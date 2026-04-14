# CLAUDE.md — Working Conventions for Claude Code

This file configures how Claude Code should operate in this repository. Read `CONTEXT.md` first for product understanding.

## Language Rules

- **All code, comments, commit messages, PR descriptions, variable names, API responses, migration names, test descriptions, and documentation → English.**
- **Chat replies to the human operator → Spanish.**
- When in doubt, English for artifacts, Spanish for conversation.

## Stack Hard Rules

- Ruby on Rails **8.x only**. Ruby **3.2+**.
- Background jobs: **Solid Queue** only. Do not introduce Sidekiq.
- Cache: **Solid Cache**. WebSockets: **Solid Cable**.
- Redis is used **only** for the A/B router (sticky-session keys + counters).
- Database: **Postgres 16+** only. No secondary DB.
- Deploys: **Kamal 2** with Kamal Proxy (not Traefik).
- UI: **Hotwire** (Turbo Frames + Turbo Streams). Stimulus only when unavoidable. No React / Vue / etc.
- Anthropic calls via the official `anthropic` gem.
- Stripe via `stripe-ruby` using **Billing Meters** (the new API, not `usage_records`).
- GitHub via `octokit`.
- Linter: `rubocop-rails-omakase`.
- Tests: Minitest + Capybara (Rails defaults).

## Architecture Rules

- Thin controllers. Business logic lives in `app/services/<Domain>/<UseCase>.rb`.
- Every service object exposes a single `call` class method.
- Use `ActiveRecord::Encrypted` for secrets at rest (API keys, OAuth tokens).
- Use strong typing for JSON columns with `ActiveModel::Attributes` / `StoreModel` where helpful.
- Migrations must be reversible. Never squash history.
- No N+1 queries — use `includes` / `preload` / `strict_loading` where relevant.
- Public API is versioned under `/api/v1/`. Use `ActiveModel::Serializer`-style plain Ruby serializers in `app/serializers/`.

## SDK (Ruby gem) Rules

- The `promptly` gem in `gem/` has **zero Rails dependency**. Pure Ruby.
- Targets Ruby 3.2+.
- Public API: `Promptly.configure`, `Promptly.get`, `Promptly.log`, `Promptly.with`.
- Emits OpenTelemetry GenAI semantic convention spans when an OTel tracer is configured.
- Ships with `opentelemetry-api` as a soft dependency (no-op if OTel not installed).
- HTTP client: `net/http` from stdlib (no gem dependency).
- Tests: Minitest.

## Git & PR Rules

- Feature branches: `feat/<slug>`, `fix/<slug>`, `chore/<slug>`.
- Commit style: Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`).
- Small PRs. One concern per PR.
- Always open a PR — never push to `main`.

## When Invoked for a New Task

1. Read `CONTEXT.md` for product context.
2. Read this file for conventions.
3. Check `prompts/` for the specific task brief.
4. Before writing code, outline the plan in the PR description (what tables, what routes, what services, what tests).
5. Write the migration / model / service / controller / view / test in that order.
6. Run `bin/rails test` and `bin/rubocop` before opening the PR.
7. Open the PR with a summary + checklist.

## Dependency Minimalism

Resist adding gems. Before adding one, justify:

- Can Rails 8 stdlib / ActiveSupport do it?
- Will this gem still be maintained in 2 years?
- Does it introduce a transitive dependency on Redis / Sidekiq / jQuery?

If any answer is uncertain, don't add it.

## Performance Budgets

- `/api/v1/prompts/:slug/resolve` p95 latency < 25ms (Redis hit path).
- `/api/v1/prompts/:slug/log` p95 latency < 15ms (enqueue only, no synchronous scoring).
- Dashboard pages < 300ms server-side render.

## Security Defaults

- All API inputs validated with strong parameters + explicit schema.
- CSRF on all web forms (Rails default).
- `secure_headers` gem for HSTS / CSP.
- API keys hashed with `bcrypt` (or `Digest::SHA256` with per-workspace salt — decide in ADR).
- Rate limit via `rack-attack`.
- Log scrubbing: never log raw prompt content or outputs in production logs.
