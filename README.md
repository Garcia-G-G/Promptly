# Promptly

> Git + Vercel, pero para tus prompts de LLM.

Promptly es una plataforma de **control de versiones y A/B testing de prompts** para desarrolladores que construyen aplicaciones con LLMs (Claude, GPT, Gemini). Trata los prompts como artefactos versionados de primera clase, con entornos, split de tráfico, rollback, evaluación y un dashboard.

## ¿Por qué?

Los devs gestionan prompts de la peor forma posible: strings hardcodeados, pegados en Notion o Slack, sin historial, sin visibilidad de si un cambio mejoró o rompió algo. Las herramientas existentes cuestan $150–$249/mes o te amarran a su cloud. Promptly apunta al dev indie y al equipo pequeño (1–5 personas) con un tier de $29/mes y paridad de features con los grandes.

## Estructura del repo

```
promptly/
├── app/           # Aplicación Rails 8 (backend + UI Hotwire)
├── gem/           # Ruby gem `promptly` (SDK, sin dependencia de Rails)
├── docs/          # Documentación del producto y ADRs
├── prompts/       # Prompts para Claude Code, uno por paso del milestone
├── CONTEXT.md     # Contexto completo del producto (leer primero)
├── CLAUDE.md      # Convenciones de trabajo para Claude Code
└── README.md
```

## Stack

- Rails 8 + Hotwire + Postgres 16 + Redis (solo A/B router)
- Solid Queue / Solid Cache / Solid Cable (nada de Sidekiq)
- Anthropic `anthropic` gem (oficial) + Claude Sonnet 4.6 para scoring
- Stripe Billing Meters
- OpenTelemetry GenAI semantic conventions
- Kamal 2 + Hetzner para deploy

Detalles completos en [`CONTEXT.md`](./CONTEXT.md).

## Cómo usar este repo con Claude Code

1. Clona el repo.
2. Abre Claude Code en la raíz (`claude` desde esta carpeta).
3. Claude leerá `CLAUDE.md` y `CONTEXT.md` automáticamente.
4. Pasa el prompt del paso actual, ej: `prompts/01-rails-app-scaffold.md`.
5. Revisa el PR, haz merge, pasa al siguiente paso.

## Convenciones

- Código, specs, nombres, commits, PRs → **inglés**.
- Comunicación con el equipo → **español**.
- Todas las instrucciones operativas en [`CLAUDE.md`](./CLAUDE.md).

## Milestones

- **Semana 1** — Backend core (modelos, CRUD, `/resolve`, A/B router, API keys)
- **Semana 2** — SDK Ruby + logging + scoring async con Claude
- **Semana 3** — UI + experiments + evals + security scan
- **Semana 4** — Canary deploys, Bayesian significance, Stripe, GitHub bot, landing, publicar gem

## Licencia

MIT — el core es open source. Cloud ofrece features operacionales y soporte.
