# Promptly

Ruby SDK for prompt version control and A/B testing.

`promptly` resolves versioned prompts at runtime, logs outputs for scoring, and
routes traffic through A/B experiments — all from a tiny, dependency-free gem.

---

## Installation

```bash
gem install promptly
```

Or add it to your `Gemfile`:

```ruby
gem "promptly"
```

Ruby 3.2+ is required.

---

## Configuration

```ruby
Promptly.configure do |c|
  c.api_key     = ENV.fetch("PROMPTLY_KEY")
  c.project     = "my-app"
  c.environment = Rails.env.production? ? :production : :dev
end
```

All options:

| Option         | Default                          | Description                                      |
| -------------- | -------------------------------- | ------------------------------------------------ |
| `api_key`      | `ENV["PROMPTLY_KEY"]`            | Workspace API key. Required.                     |
| `project`      | `ENV["PROMPTLY_PROJECT"]`        | Project slug within the workspace. Required.     |
| `environment`  | `ENV["PROMPTLY_ENV"]` or `:dev`  | `:dev`, `:staging`, `:production`.               |
| `base_url`     | `https://api.promptly.dev`       | Override for self-hosted deployments.            |
| `timeout`      | `5`                              | HTTP request timeout in seconds.                 |
| `otel_enabled` | `false`                          | Emit OpenTelemetry GenAI spans.                  |
| `logger`       | `nil`                            | Any logger responding to `debug`/`info`/`warn`.  |

---

## Usage

### Resolve a prompt

```ruby
prompt = Promptly.get("onboarding-email", vars: { name: "Ada" })

prompt.content       # => "Hi Ada, welcome to ..."
prompt.version       # => 7
prompt.environment   # => "production"
prompt.experiment    # => "tone-tweak" (or nil)
prompt.variant       # => "B" (or nil)
prompt.model_hint    # => "claude-sonnet-4-6" (or nil)
```

### Log an output

Non-blocking — logs are batched server-side for scoring.

```ruby
Promptly.log(
  prompt_slug: "onboarding-email",
  output:      response.content.first.text,
  request_id:  prompt.request_id,
  latency_ms:  42,
  tokens:      { input: 320, output: 180 },
  model_version: "claude-sonnet-4-6"
)
```

### Block form (`Promptly.with`)

Wraps resolution, timing, and logging in a single call. The block receives the
resolved prompt; its return value is logged automatically.

```ruby
answer = Promptly.with("doc-summarizer", vars: { language: "es" }) do |prompt|
  anthropic.messages.create(
    model:    prompt.model_hint || "claude-sonnet-4-6",
    messages: [{ role: "user", content: prompt.to_s }]
  )
end
```

`Promptly.with` captures latency, extracts the output text, and posts a log
entry on your behalf.

---

## OpenTelemetry

When `opentelemetry-api` is available in your app, Promptly emits spans that
follow the GenAI semantic conventions.

```ruby
require "opentelemetry/sdk"

OpenTelemetry::SDK.configure do |c|
  c.service_name = "my-app"
  c.use_all
end

Promptly.configure do |c|
  c.api_key     = ENV.fetch("PROMPTLY_KEY")
  c.project     = "my-app"
  c.otel_enabled = true
end
```

Each `Promptly.get` and `Promptly.with` call produces a span with attributes
such as `gen_ai.prompt.slug`, `gen_ai.prompt.version`, `gen_ai.experiment.id`,
and `gen_ai.response.latency_ms`.

If `opentelemetry-api` is not installed, instrumentation silently no-ops.

---

## Error handling

All SDK errors inherit from `Promptly::Error`.

| Class                           | Raised when                                          |
| ------------------------------- | ---------------------------------------------------- |
| `Promptly::ConfigurationError`  | `api_key` or `project` are missing at call time.     |
| `Promptly::AuthenticationError` | API key is invalid or expired.                       |
| `Promptly::ForbiddenError`      | Key lacks access to the requested project/prompt.    |
| `Promptly::NotFoundError`       | Prompt slug does not exist for the environment.      |
| `Promptly::ValidationError`     | Request payload was rejected by the server.          |
| `Promptly::RateLimitError`      | Too many requests — back off and retry.              |
| `Promptly::ServerError`         | Upstream 5xx response.                               |
| `Promptly::TimeoutError`        | Request exceeded `timeout` seconds.                  |
| `Promptly::ConnectionError`     | DNS, TLS, or socket failure.                         |

```ruby
begin
  Promptly.get("doc-summarizer")
rescue Promptly::NotFoundError
  # fall back to a default prompt
rescue Promptly::Error => e
  Rails.logger.warn("[promptly] #{e.class}: #{e.message}")
end
```

---

## Links

- Documentation: <https://docs.promptly.dev/ruby-sdk>
- Changelog: [`CHANGELOG.md`](CHANGELOG.md)
- Issues: <https://github.com/promptly-dev/promptly-ruby/issues>
- Source: <https://github.com/promptly-dev/promptly-ruby>

---

## License

MIT © Promptly.
