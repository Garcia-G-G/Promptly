# Promptly — Project Context

> **For Claude Code**: This document is the source of truth for the Promptly product. Read it fully before any implementation task. All code, comments, specs, API responses, and variable names must be in English. Conversational replies to the human operator may be in Spanish.

---

## 1. Product Overview

**Promptly** is a prompt version control and A/B testing platform for developers building LLM-powered applications. It treats prompts as first-class versioned artifacts — with environments, traffic splitting, rollback, evaluation, and a dashboard — so teams stop managing prompts as hardcoded strings and start shipping them like code.

- **Tagline**: *Git + Vercel, but for your LLM prompts.*
- **Target user**: Solo developers and small teams (1–5 people) shipping production apps with Claude, GPT, or Gemini. Rails developers are the first beachhead.
- **Positioning vs competitors (2026)**: Prompt management **first**, observability as a complement. Indie-friendly price, Ruby-native DX, feature parity with $249/mo tools at a $29/mo tier.

## 2. The Problem

Developers building with LLMs manage prompts in the worst possible ways: hardcoded strings in source code, copy-pasted into Notion / Google Docs / Slack, no history, no visibility into whether a change improved or broke things, and custom-built A/B infrastructure for every project.

Existing tools:

- Braintrust / Humanloop: $150–249/month.
- LangSmith: cloud lock-in.
- Langfuse: great but observability-first; prompt management is secondary.
- PromptLayer: strong replay feature; $49/mo.
- Agenta / Promptfoo: OSS but either limited or CLI-only.

**Gap Promptly fills**: prompt-management-first product, Ruby/Rails-native, indie pricing, with 2026 features (OTel GenAI, canary deploys, LLM-as-judge, eval datasets, security scans) at the Starter tier.

## 3. The Solution — Feature Set

1. **Version control for prompts** — every prompt has a slug, immutable history, unique SHA-256 content hash. Push via SDK or UI.
2. **Environments** — `dev` / `staging` / `production`. Promote a version through environments before it hits users.
3. **Live A/B traffic splitting** — define 70/30 or 50/50 splits; SDK routes requests automatically with sticky sessions; Bayesian significance detection surfaces winner.
4. **Canary promotion** — gradual rollout 1% → 10% → 50% → 100% with auto-rollback if quality score drops.
5. **Diff viewer + one-click rollback** — side-by-side diff between any two versions.
6. **SDK in 3 lines** — Ruby gem first (`promptly` gem), then Python, then JS.
7. **Replay / time-travel debugging** — every `Promptly.log` stores input+output+vars; any past request can be re-run from the UI with a different prompt or model.
8. **Eval datasets** — upload CSV of test cases; new versions run automatically before promote-to-production is allowed.
9. **Configurable LLM-as-judge** — users define their own scoring prompts (quality, tone, factuality, custom). Scorers are versioned resources.
10. **Security scans** — detect prompt injection, PII leakage, jailbreak risks in new versions (inspired by Promptfoo).
11. **OpenTelemetry GenAI native** — SDK emits OTel `gen_ai.*` spans out of the box (Datadog / Honeycomb / Grafana work with zero extra code).
12. **GitHub PR integration** — bot comments on PRs touching prompts: what changed, active experiments, expected impact.

## 4. Tech Stack (Updated for 2026)

| Layer | Technology | Notes |
|---|---|---|
| Backend API | **Ruby on Rails 8** | Rails 8 conventions only. No legacy patterns. |
| Frontend / UI | **Hotwire (Turbo + Stimulus)** | No custom JS frameworks. |
| Database | **PostgreSQL 16+** | Single-database architecture. |
| Background jobs | **Solid Queue** | Replaces Sidekiq in Rails 8. Postgres-backed. |
| Cache | **Solid Cache** | Postgres-backed. |
| WebSockets | **Solid Cable** | Postgres-backed. |
| A/B router + counters | **Redis** | Only remaining Redis dependency. Sticky sessions + atomic counters. |
| AI scoring | **Anthropic Ruby SDK** (`anthropic` gem) + `claude-sonnet-4-6` | Official SDK. Supports streaming + retries + types. |
| Infrastructure | **Hetzner CX21 + Kamal 2** | Kamal Proxy (not Traefik); Let's Encrypt SSL; zero-downtime deploys. |
| Auth (web) | **Devise** | Standard. |
| Auth (SDK) | **API keys** (digest stored) | Per-workspace; revocable; `last_used_at` tracked. |
| Payments | **Stripe Billing Meters** (not `usage_records`) | New API as of 2026; supports LLM-token native metering. |
| Observability | **OpenTelemetry GenAI semconv** | SDK emits spans; server exposes OTLP endpoint. |
| SDK (Ruby) | `promptly` gem | Zero Rails dependency; pure Ruby; Ruby 3.2+. |
| SDK (Python) | `promptly-py` | Phase 2. |
| SDK (JS) | `@promptly/js` | Phase 2. |

## 5. Data Models

```ruby
Workspace
  id, name, slug, owner_id, plan, stripe_customer_id, stripe_meter_id
  has_many :projects, :api_keys, :members

Membership
  workspace_id, user_id, role (owner, admin, developer, viewer)

Project
  id, workspace_id, name, slug
  has_many :prompts, :datasets, :scorers

Prompt
  id, project_id, slug, description
  has_many :prompt_versions, :experiments, :logs

PromptVersion
  id, prompt_id, version_number (int)
  content (text), variables (jsonb)
  model_hint (string, e.g. "claude-sonnet-4-6")
  environment (enum: dev, staging, production, archived)
  content_hash (sha256), parent_version_id (for branching)
  created_by_id, created_at

Experiment
  id, prompt_id, name, status (draft, running, paused, concluded)
  variant_a_version_id, variant_b_version_id
  traffic_split (int — percent to variant_a)
  canary_stage (null | 1 | 10 | 50 | 100)
  auto_rollback_threshold (float | null)
  winner_version_id, started_at, concluded_at

ExperimentResult
  id, experiment_id, variant (enum: a, b)
  request_id (string), input_vars (jsonb), output (text)
  latency_ms (int), prompt_tokens (int), completion_tokens (int), cost_cents (int)
  model_version (string), git_sha (string, nullable)
  score (float | null), scorer_id (fk | null)
  created_at
  index on (experiment_id, variant, created_at)

Dataset
  id, project_id, name
  has_many :dataset_rows

DatasetRow
  id, dataset_id, input_vars (jsonb), expected_output (text | null), tags (jsonb)

Scorer
  id, project_id, name, scorer_type (enum: llm_judge, exact_match, regex, custom)
  content (text — for llm_judge this is the scoring prompt)
  model_hint (string)
  version_number (int)

EvalRun
  id, prompt_version_id, dataset_id, scorer_id
  status (enum: queued, running, done, failed)
  aggregate_score (float), pass_rate (float)
  started_at, finished_at

SecurityScan
  id, prompt_version_id
  status (enum: queued, running, clean, flagged)
  findings (jsonb — list of { type, severity, description })

Log
  id, prompt_id, prompt_version_id, request_id
  input_vars (jsonb), output (text)
  latency_ms, tokens (jsonb), model_version
  experiment_id (nullable), variant (nullable)
  otel_trace_id, otel_span_id
  created_at

ApiKey
  id, workspace_id, name, key_digest, last_used_at, revoked_at
```

## 6. SDK Interface (Ruby — target DX)

```ruby
# Gemfile
gem "promptly"

# config/initializers/promptly.rb
Promptly.configure do |c|
  c.api_key = ENV.fetch("PROMPTLY_KEY")
  c.project = "my-app"
  c.environment = Rails.env.production? ? :production : :dev
  c.otel_enabled = true
end

# Basic usage
prompt = Promptly.get("doc-summarizer")
# => returns active prompt content for this env/experiment

# With variable interpolation
prompt = Promptly.get("doc-summarizer", vars: { language: "Spanish", length: "3 bullets" })

# With explicit environment override
prompt = Promptly.get("doc-summarizer", env: :staging)

# Logging for A/B tracking + replay
Promptly.log(
  prompt_slug: "doc-summarizer",
  request_id: req_id,
  output: response_text,
  input_vars: { ... },
  latency_ms: 230,
  tokens: { prompt: 1200, completion: 340 },
  model_version: "claude-sonnet-4-6"
)

# Block form — auto-logs input/output/latency and wraps in OTel span
Promptly.with("doc-summarizer", request_id: req_id, vars: { ... }) do |prompt|
  anthropic.messages.create(model: prompt.model_hint, messages: [{ role: "user", content: prompt.to_s }])
end
```

## 7. HTTP API (Rails routes)

```
POST   /api/v1/prompts/:slug/resolve      # SDK — returns active version content
POST   /api/v1/prompts/:slug/log          # SDK — logs an output result
GET    /api/v1/prompts                    # List prompts in project
POST   /api/v1/prompts                    # Create prompt
POST   /api/v1/prompts/:slug/versions     # Push new version
POST   /api/v1/prompts/:slug/promote      # Promote version to environment
GET    /api/v1/experiments                # List experiments
POST   /api/v1/experiments                # Create experiment
PATCH  /api/v1/experiments/:id            # Update (pause, conclude, advance_canary)
POST   /api/v1/datasets                   # Create dataset
POST   /api/v1/datasets/:id/rows          # Bulk insert rows (CSV)
POST   /api/v1/eval_runs                  # Run a prompt_version against dataset+scorer
POST   /api/v1/replays                    # Re-run a Log with a different prompt_version
```

Auth: `Authorization: Bearer <api_key>`. Rate limits: 1000 req/min per key (Starter), 10k/min (Pro).

## 8. A/B Traffic Split Logic

On `POST /api/v1/prompts/:slug/resolve` when an experiment is `running`:

```
1. Check Redis for existing assignment: "exp:{experiment_id}:req:{request_id}"
2. If exists → return cached variant (sticky sessions)
3. Else → hash(request_id) -> float 0..1
   - float < (split/100) → variant A
   - else → variant B
4. Store assignment in Redis with TTL 24h
5. Increment Redis counter: "exp:{experiment_id}:variant:{a|b}:count"
6. If canary_stage active, additional gate: only route into experiment if hash bucket < canary_stage%
7. Return prompt content + X-Promptly-Variant header
```

### Bayesian significance (hourly Solid Queue job)

- Use Beta-Binomial conjugate prior on quality score (normalized 0..1).
- Sequential sampling per arXiv 2511.10661: stop early when P(winner) > 0.95 or expected loss < ε.
- On conclusion: set `winner_version_id`, notify owner via email + webhook + Slack.

### Auto-rollback (canary)

- During canary stages (1%, 10%, 50%), if running aggregate score drops below `auto_rollback_threshold` for N=50 consecutive results, auto-pause experiment and revert production to previous version.

## 9. Async Output Scoring

On `POST /log` with `output`:

- Enqueue `ScoreOutputJob` (Solid Queue).
- Job resolves the `Scorer` for the prompt (default LLM-judge scorer if none configured).
- For `llm_judge` scorer, build Anthropic message:

```
System: You are an output quality evaluator. Score the following LLM output on quality, relevance, and helpfulness. Return ONLY JSON: {"score": 0.0, "rationale": "…"}

User:
Prompt used: {prompt_content}
Variables: {input_vars}
Output received: {output}
```

- Parse JSON; persist `score` + `rationale` on `ExperimentResult` / `Log`.
- Respect rate limits with exponential backoff + Solid Queue retry.

## 10. Security Scanning

On every new `PromptVersion`, enqueue `SecurityScanJob`:

- Pattern-check for: role-override strings, "ignore previous", "system prompt", data-exfil patterns.
- LLM-assisted jailbreak review (Claude).
- PII heuristics on default variable values.
- Store `SecurityScan.findings`. Block promotion to `production` if `status=flagged` unless user overrides.

## 11. UI Pages (Rails + Hotwire)

```
/                         Landing
/signup  /login           Devise
/dashboard                Workspace overview
/projects/:slug           Prompts list
/projects/:slug/prompts/:slug              Prompt detail (current env versions)
/projects/:slug/prompts/:slug/versions     Version history + diff viewer
/projects/:slug/prompts/:slug/experiments  Experiments + live results
/projects/:slug/prompts/:slug/logs         Logs + replay
/projects/:slug/datasets                   Datasets
/projects/:slug/scorers                    Scorers
/projects/:slug/eval_runs                  Eval runs
/settings/api_keys
/settings/billing
/settings/team
```

Updates: Turbo Streams for live experiment counters, Turbo Frames for diff/version panels, Stimulus only for the diff viewer split-pane.

## 12. Pricing Tiers

| Plan | Price | Limits | Notes |
|---|---|---|---|
| **Open Source** | $0 | Unlimited (self-hosted) | MIT, Docker Compose, full feature parity. |
| **Cloud Starter** | $29/month | 5 projects, 50k SDK calls/mo, 3 active experiments, 100 eval runs/mo | Indie-dev target. |
| **Cloud Pro** | $79/month | Unlimited projects, 500k calls, unlimited experiments, GitHub integration, Slack alerts, team members, security scans | |
| **Overage** | $0.0002/call | via Stripe Billing Meters | For Starter & Pro. |

## 13. Milestones

**Week 1 — Backend core**
- Rails 8 app, Postgres schema, Devise + Memberships.
- Workspace/Project/Prompt/PromptVersion CRUD.
- `/resolve` endpoint with environment logic.
- Basic Redis A/B router (no canary yet).
- API key auth.

**Week 2 — SDK + logging + scoring**
- `promptly` Ruby gem (`get`, `log`, `with` block form, OTel instrumentation).
- `/log` endpoint + `Log` + `ExperimentResult` storage.
- Solid Queue + `ScoreOutputJob` hitting Anthropic.
- Default LLM-judge scorer.

**Week 3 — UI + experiments + evals**
- Dashboard, project view, prompt detail.
- Diff viewer (side-by-side).
- Experiment creation + live results (Turbo Streams).
- Dataset upload + eval runs.
- Security scan on new versions.

**Week 4 — Launch prep**
- Canary promotion + auto-rollback.
- Bayesian significance job.
- Stripe Billing Meters + plan gates.
- GitHub PR bot (webhook listener).
- Replay UI.
- Landing page + README.
- Publish `promptly` gem to rubygems.org.

## 14. Conventions

- **All code, API, specs, migrations, variable names, comments → English.**
- **Conversational replies to the operator → Spanish.**
- Use Rails 8 conventions only. No legacy patterns (no `form_for`, etc.).
- Hotwire (Turbo Frames + Turbo Streams) for all UI updates. Stimulus only when absolutely needed.
- Thin controllers; business logic in `app/services/` (one class per use case).
- Use `ActiveRecord::Encrypted` for API keys at rest.
- Background processing via **Solid Queue** only.
- Postgres only — no secondary DB.
- Stripe webhook handling via `stripe-ruby`. GitHub via `octokit`.
- Testing: `minitest` + `capybara` (Rails defaults). Fixtures over factories where possible.
- Linting: `rubocop-rails-omakase` (Rails 8 default).
- Dependency minimalism: resist adding gems unless clear justification.

## 15. Repo Layout (Monorepo)

```
promptly/
├── app/           # Rails 8 application
├── gem/           # promptly Ruby gem (SDK, standalone)
├── docs/          # product docs, architecture decisions
├── prompts/       # Claude Code task prompts (one per milestone step)
├── CONTEXT.md     # this file
├── README.md
└── CLAUDE.md      # Claude Code working conventions
```
