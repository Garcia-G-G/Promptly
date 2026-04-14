# ADR 0001 — Stack Choices for Promptly

- **Status**: Accepted
- **Date**: 2026-04-14

## Context

Promptly ships as a Rails 8 application + a Ruby SDK gem + Postgres + Redis + Hetzner/Kamal. We need to lock in the big decisions before writing code so we don't introduce accidental complexity.

## Decisions

### 1. Rails 8 with the "Solid" stack

Use Solid Queue (not Sidekiq), Solid Cache (not Memcached/Redis), Solid Cable (not Redis pubsub). One production dependency fewer (Redis-for-Sidekiq) and proven at HEY scale.

**Redis stays only for the A/B router** — atomic counters and sticky-session TTL keys are a natural fit for Redis and not for Postgres.

### 2. Postgres 16+ only

No secondary store. Everything (users, prompts, versions, logs, eval results) lives in Postgres. Use `jsonb` for flexible fields (variables, tokens, findings).

### 3. Hotwire end-to-end

Turbo Frames + Turbo Streams for UI updates. Stimulus only where unavoidable (diff viewer split-pane). No React / Vue / Svelte. Rationale: solo/small teams maintain one mental model.

### 4. Anthropic official Ruby SDK

Use the `anthropic` gem (official). Shipped in 2025 with types in RBS/RBI, streaming, retries, error handling. Preferred over community gems or raw HTTP.

### 5. Stripe Billing Meters (not `usage_records`)

`usage_records` is deprecated by Stripe as of 2026. Billing Meters support high-throughput ingestion and the new LLM-token native billing primitives. This matches our overage model ($0.0002/call).

### 6. OpenTelemetry GenAI semantic conventions from day 1

The SDK emits OTel `gen_ai.*` spans. Customers with Datadog / Honeycomb / Grafana get instant observability without us building integrations. Langfuse and Braintrust have not fully adopted this yet — we ship it as a differentiator.

### 7. Kamal 2 + Hetzner CX21

Kamal 2 with Kamal Proxy (replaces Traefik in Kamal 1), Let's Encrypt SSL, zero-downtime deploys. Hetzner CX21 (~$6/mo) is adequate for the first hundred customers; we can scale vertically cheaply or go multi-node with Kamal accessories.

### 8. Monorepo

`app/` (Rails) and `gem/` (SDK) in one repo, published as two distinct artifacts. We can split later if it becomes painful. Benefits now: atomic changes across API + SDK, one CI config.

### 9. Ruby gem has zero Rails dependency

The `promptly` gem must run in any Ruby 3.2+ process (including non-Rails services). HTTP via stdlib `net/http`. OTel is a soft dependency.

## Consequences

- We are betting on the Rails 8 Solid-stack direction. If Solid Queue hits a performance ceiling we have not seen at HEY, we may need Sidekiq later.
- Using Billing Meters means we cannot support customers on older Stripe accounts without Billing Meters access — acceptable.
- OTel GenAI conventions are still evolving; we pin to the current major and update on stable releases.

## Revisit triggers

- If Solid Queue p95 enqueue latency exceeds 50ms under production load, reconsider.
- If we need WebSocket fan-out > 10k concurrent clients, reconsider Solid Cable.
