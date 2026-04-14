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
    model_hint: "claude-sonnet-4-6",
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

puts "Seeding complete."
puts "  Owner: #{owner.email}"
puts "  Workspace: #{workspace.slug}"
puts "  Project: playground"
puts "  Prompt: #{prompt.slug} (dev/staging/production versions)"
puts "  API Key: #{api_key.name} (#{api_key.key_prefix}...)"
