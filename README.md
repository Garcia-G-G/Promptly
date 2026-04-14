# Promptly

> Git + Vercel, but for your LLM prompts.

Promptly is a **prompt version control and A/B testing platform** for developers building applications with LLMs. It treats prompts as first-class versioned artifacts — with environments, traffic splitting, rollback, evaluation, and a dashboard — so teams stop managing prompts as hardcoded strings and start shipping them like code.

## The Problem

Developers building with LLMs manage prompts in the worst possible ways: hardcoded strings buried in source code, copy-pasted into Notion or Slack, no history, and zero visibility into whether a change improved or broke things. When it's time to A/B test a prompt, everyone builds custom infrastructure from scratch.

Existing tools charge $150–$249/month, lock you into their cloud, or treat prompt management as an afterthought behind observability dashboards.

## How Promptly Works

### Version Control for Prompts

Every prompt has a slug, immutable version history, and a unique SHA-256 content hash. Push new versions via the SDK or UI — every change is tracked, diffable, and reversible.

### Environments

Prompts flow through `dev` → `staging` → `production`, just like code. Promote a version through environments before it reaches users. Roll back to any previous version with one click.

### A/B Testing with Live Traffic Splitting

Define 70/30 or 50/50 splits between prompt variants. The SDK routes requests automatically with sticky sessions so the same user always sees the same variant. Bayesian significance detection tells you when a winner emerges.

### Canary Promotion

Roll out a new prompt version gradually: 1% → 10% → 50% → 100%. If quality scores drop below your threshold, Promptly auto-rolls back to the previous version.

### Eval Datasets & LLM-as-Judge Scoring

Upload test cases as CSV. New prompt versions run against your dataset automatically before promotion to production is allowed. Configure custom scoring prompts (quality, tone, factuality) — scorers are versioned resources too.

### Security Scanning

Every new prompt version is scanned for prompt injection patterns, PII leakage, and jailbreak risks before it can be promoted to production.

### SDK in 3 Lines

```ruby
Promptly.configure { |c| c.api_key = ENV["PROMPTLY_KEY"] }

prompt = Promptly.get("doc-summarizer", vars: { language: "Spanish" })
```

The SDK handles environment resolution, A/B routing, variable interpolation, and logging — all in one call. Ruby first, Python and JavaScript coming soon.

### Replay & Time-Travel Debugging

Every logged request stores input, output, and variables. Re-run any past request from the UI with a different prompt version or model to see what would have changed.

### OpenTelemetry Native

The SDK emits `gen_ai.*` spans out of the box. If you already use Datadog, Honeycomb, or Grafana, you get instant observability with zero extra code.

### GitHub Integration

A bot comments on PRs that touch prompts: what changed, active experiments, and expected impact.

## Pricing

| Plan | Price | Includes |
|------|-------|----------|
| **Open Source** | Free | Self-hosted, full features, unlimited usage |
| **Cloud Starter** | $29/mo | 5 projects, 50k SDK calls/mo, 3 experiments, 100 eval runs/mo |
| **Cloud Pro** | $79/mo | Unlimited projects & experiments, GitHub + Slack integration, security scans |

Overage: $0.0002 per additional SDK call.

## License

MIT — the core is open source. Cloud adds operational features and support.
