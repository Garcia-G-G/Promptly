# Changelog

## 0.1.0 (2026-04-17)

- Initial release
- `Promptly.configure` - set API key, project, environment
- `Promptly.get` - resolve prompt with variable interpolation
- `Promptly.log` - log output for A/B tracking
- `Promptly.with` - block form with auto-logging and OTel spans
- OpenTelemetry GenAI semantic convention support (soft dependency)
- Retry logic with exponential backoff
- Full error mapping (401, 403, 404, 422, 429, 5xx)
