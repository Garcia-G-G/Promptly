puts "Seeding database..."

owner = User.find_or_create_by!(email: ENV.fetch("SEED_OWNER_EMAIL", "owner@promptly.dev")) do |u|
  u.password = ENV.fetch("SEED_OWNER_PASSWORD", "promptly-dev")
  u.name = "Demo Owner"
end
owner.confirm unless owner.confirmed?

workspace = Workspace.find_or_create_by!(slug: "demo") do |w|
  w.name = "Demo"
  w.owner = owner
end

Membership.find_or_create_by!(workspace: workspace, user: owner) do |m|
  m.role = :owner
end

project = Project.find_or_create_by!(workspace: workspace, slug: "playground") do |p|
  p.name = "Playground"
end

scorer = Scorer.find_or_create_by!(project: project, name: "default-quality") do |s|
  s.scorer_type = :llm_judge
  s.content = <<~PROMPT
    You are an output quality evaluator. Score the following LLM output on three dimensions:
    1. Quality — is the output well-written, clear, and complete?
    2. Relevance — does the output address the prompt accurately?
    3. Helpfulness — would a user find this output useful?

    Return ONLY valid JSON with no additional text:
    {"score": 0.0, "rationale": "one sentence explanation"}

    The score must be a float between 0.0 and 1.0 where:
    - 0.0–0.3 = poor
    - 0.3–0.6 = acceptable
    - 0.6–0.8 = good
    - 0.8–1.0 = excellent
  PROMPT
  s.model_hint = "gpt-4o"
end
puts "  Scorer: #{scorer.name} (#{scorer.scorer_type})"

# Prompt + versions
prompt = Prompt.find_or_create_by!(project: project, slug: "doc-summarizer") do |p|
  p.description = "Summarizes documents in the specified language and format"
end

# Dev version
unless prompt.prompt_versions.exists?(environment: "dev")
  PromptVersions::Push.call(
    prompt: prompt,
    content: "You are a document summarizer.\n\nSummarize the following document in {language}.\nFormat: {length}.\n\nDocument:\n{document}",
    variables: [
      { "name" => "language", "description" => "Target language", "default" => "English" },
      { "name" => "length", "description" => "Output format", "default" => "3 bullet points" },
      { "name" => "document", "description" => "The document to summarize", "default" => "" }
    ],
    model_hint: "gpt-4o",
    created_via: :api
  )
end

# Promote to staging and production
dev_version = prompt.prompt_versions.find_by(environment: "dev")
unless prompt.prompt_versions.exists?(environment: "staging")
  PromptVersions::Promote.call(prompt_version: dev_version, to_environment: :staging)
end
unless prompt.prompt_versions.exists?(environment: "production")
  PromptVersions::Promote.call(prompt_version: dev_version, to_environment: :production)
end

# API Key for the demo workspace
api_key = ApiKey.find_by(workspace: workspace, name: "dev-seed-key")
unless api_key
  api_key = ApiKey.create!(workspace: workspace, name: "dev-seed-key")
  puts ""
  puts ">>> DEV API KEY (copy now, will not be shown again): #{api_key.raw_key}"
  puts ""
else
  puts ""
  puts ">>> DEV API KEY already exists (key_prefix: #{api_key.key_prefix}...)"
  puts ""
end

# Create alternative version for A/B testing
alt_dev_version = nil
unless prompt.prompt_versions.exists?(content: "You are a concise document summarizer.\n\nProvide a brief summary of the following document in {language}.\nUse {length} format. Be direct and avoid filler.\n\nDocument:\n{document}")
  # Archive current dev to make room for the new one
  current_dev = prompt.prompt_versions.find_by(environment: "dev")
  current_dev&.update!(environment: :archived)

  alt_dev_version = PromptVersions::Push.call(
    prompt: prompt,
    content: "You are a concise document summarizer.\n\nProvide a brief summary of the following document in {language}.\nUse {length} format. Be direct and avoid filler.\n\nDocument:\n{document}",
    variables: [
      { "name" => "language", "description" => "Target language", "default" => "English" },
      { "name" => "length", "description" => "Output format", "default" => "3 bullet points" },
      { "name" => "document", "description" => "The document to summarize", "default" => "" }
    ],
    created_via: :api
  )
end

# Create demo experiment
prod_version = prompt.prompt_versions.find_by(environment: "production")
alt_version = alt_dev_version || prompt.prompt_versions.where(environment: %w[dev archived]).order(version_number: :desc).first

unless prompt.experiments.exists?(name: "tone-tweak")
  if prod_version && alt_version && prod_version.id != alt_version.id
    exp = Experiment.create!(
      prompt: prompt,
      name: "tone-tweak",
      variant_a_version: prod_version,
      variant_b_version: alt_version,
      traffic_split: 50,
      environment: "production",
      canary_stage: 10,
      status: :running,
      started_at: Time.current
    )
    puts "  Experiment: #{exp.name} (running, canary_stage: #{exp.canary_stage})"
  end
end

# Dataset with sample test cases
dataset = Dataset.find_or_create_by!(project: project, name: "summarizer-test-cases") do |d|
  d.description = "Test cases for the doc-summarizer prompt"
end

if dataset.dataset_rows.count == 0
  Datasets::ImportRows.call(dataset: dataset, rows: [
    { input_vars: { "language" => "Spanish", "length" => "3 bullets", "document" => "Ruby is a programming language." }, expected_output: "Spanish summary in 3 bullets", tags: [ "core" ] },
    { input_vars: { "language" => "English", "length" => "1 paragraph", "document" => "Rails is a web framework." }, tags: [ "core" ] },
    { input_vars: { "language" => "French", "length" => "5 bullets", "document" => "PostgreSQL is a database." }, tags: [ "i18n" ] },
    { input_vars: { "language" => "English", "length" => "3 bullets", "document" => "" }, tags: [ "edge-case" ] },
    { input_vars: { "language" => "Japanese", "length" => "1 sentence", "document" => "Redis is an in-memory store." }, tags: [ "i18n" ] }
  ])
end
puts "  Dataset: #{dataset.name} (#{dataset.dataset_rows.count} rows)"

# Pre-computed eval run (don't call Claude in seeds)
prod_version = prompt.prompt_versions.find_by(environment: "production")
if prod_version && !EvalRun.exists?(prompt_version: prod_version, dataset: dataset)
  eval_run = EvalRun.create!(
    prompt_version: prod_version,
    dataset: dataset,
    scorer: scorer,
    status: :done,
    aggregate_score: 0.78,
    pass_rate: 0.80,
    pass_threshold: 0.6,
    total_rows: 5,
    scored_rows: 5,
    started_at: 1.hour.ago,
    finished_at: 30.minutes.ago
  )
  puts "  EvalRun: #{eval_run.status} (score: #{eval_run.aggregate_score})"
end

# Security scan for production version
if prod_version && !SecurityScan.exists?(prompt_version: prod_version)
  SecurityScan.create!(
    prompt_version: prod_version,
    status: :clean,
    findings: [],
    started_at: 1.hour.ago,
    finished_at: 1.hour.ago
  )
  puts "  SecurityScan: clean"
end

puts "Seeding complete."
puts "  Owner: #{owner.email}"
puts "  Workspace: #{workspace.slug}"
puts "  Project: playground"
puts "  Prompt: #{prompt.slug} (dev/staging/production versions)"
puts "  API Key: #{api_key.name} (#{api_key.key_prefix}...)"
