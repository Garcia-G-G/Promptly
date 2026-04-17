# Promptly

> Git + Vercel, but for your LLM prompts.

Promptly is a **prompt version control and A/B testing platform** for developers building applications with LLMs (GPT, Gemini, etc.). It treats prompts as first-class versioned artifacts, with environments, traffic splitting, rollback, evaluation, and a dashboard.

## Why?

Developers manage prompts in the worst possible ways: hardcoded strings, pasted into Notion or Slack, no history, no visibility into whether a change improved or broke things. Existing tools cost $150–$249/month or lock you into their cloud. Promptly targets indie developers and small teams (1–5 people) with a $29/month tier and feature parity with the big players.

## Repo structure

```
promptly/
├── app/           # Rails 8 application (backend + Hotwire UI)
├── gem/           # Ruby gem `promptly` (SDK, zero Rails dependency)
├── docs/          # Product documentation and ADRs
├── prompts/       # Task briefs, one per milestone step
├── CONTEXT.md     # Full product context (read first)
├── CLAUDE.md      # Working conventions
└── README.md
```

## Stack

- Rails 8 + Hotwire + Postgres 16 + Redis (A/B router only)
- Solid Queue / Solid Cache / Solid Cable (no Sidekiq)
- Stripe Billing Meters
- OpenTelemetry GenAI semantic conventions
- Kamal 2 + Hetzner for deploys

Full details in [`CONTEXT.md`](./CONTEXT.md).

## Local development

```bash
cd app
bin/setup        # install gems, create DB, run migrations, seed
bin/dev          # start Rails server + Solid Queue via foreman
```

The seed command prints a dev API key on first run — copy it, it won't be shown again.

## Conventions

- All code, specs, variable names, commits, PRs → **English**
- All operational instructions in [`CLAUDE.md`](./CLAUDE.md)

## Milestones

- **Week 1** — Backend core (models, CRUD, `/resolve`, A/B router, API keys)
- **Week 2** — Ruby SDK + logging + async scoring
- **Week 3** — UI + experiments + evals + security scan
- **Week 4** — Canary deploys, Bayesian significance, Stripe, GitHub bot, landing, publish gem

## License

MIT — the core is open source. Cloud offers operational features and support.
