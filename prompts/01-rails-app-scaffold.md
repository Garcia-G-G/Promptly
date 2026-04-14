# Task 01 — Rails 8 App Scaffold + Auth + Workspace Model

## Goal

Initialize the Rails 8 application inside `app/` with Postgres, Devise, multi-tenant foundations (Workspace + Membership), and the baseline CI/dev scripts. This is the foundation every later task builds on.

## Prerequisites you must read first

1. `CONTEXT.md` at the repo root — full product spec.
2. `CLAUDE.md` at the repo root — working conventions (language, stack rules, architecture).

If anything in this task brief conflicts with `CONTEXT.md` or `CLAUDE.md`, **stop and ask**.

## Deliverables

1. A new Rails 8 app generated inside `app/` with:
   - `--database=postgresql`
   - `--skip-jbuilder` (we will write plain Ruby serializers)
   - Solid Queue / Solid Cache / Solid Cable enabled (Rails 8 defaults — do not disable)
   - Propshaft + Importmap (Rails 8 defaults)
   - Rubocop Omakase enabled

2. Gemfile additions (justify each in the PR description):
   - `devise` — web auth
   - `stripe` — billing
   - `octokit` — GitHub PR bot
   - `anthropic` — official Anthropic Ruby SDK
   - `opentelemetry-sdk`, `opentelemetry-instrumentation-rails` — tracing
   - `rack-attack` — rate limiting
   - `secure_headers` — HSTS / CSP
   - `redis` — only for A/B router (not for Sidekiq; we are on Solid Queue)

   Dev/test only:
   - `dotenv-rails`
   - `faker`

3. Devise install and a `User` model with:
   - Standard Devise modules: `database_authenticatable, registerable, recoverable, rememberable, validatable, confirmable`
   - `name:string`

4. Multi-tenant models — migrations and models:

   ```ruby
   Workspace
     name:string  slug:string(unique)  plan:string(default: "starter")
     stripe_customer_id:string  stripe_meter_id:string
     owner_id:references(User)
     timestamps
     has_many :memberships, dependent: :destroy
     has_many :users, through: :memberships
     has_many :projects, dependent: :destroy
     has_many :api_keys, dependent: :destroy
     validates :slug, presence: true, uniqueness: true,
       format: { with: /\A[a-z0-9-]+\z/ }

   Membership
     workspace_id:references  user_id:references
     role:string  # enum: owner, admin, developer, viewer
     timestamps
     validates :role, inclusion: { in: %w[owner admin developer viewer] }
     validates :user_id, uniqueness: { scope: :workspace_id }
   ```

   Add `enum :role, { owner: "owner", admin: "admin", developer: "developer", viewer: "viewer" }, prefix: true` on `Membership`.

5. `ApplicationController`:
   - `before_action :authenticate_user!`
   - `helper_method :current_workspace`
   - `current_workspace` resolves from `params[:workspace_slug]` and guards access via `Membership`.
   - Redirect unauthenticated requests to the Devise sign-in page.

6. Route skeleton (no logic yet, just placeholders returning 200 with a TODO string):

   ```ruby
   root "marketing#index"
   devise_for :users

   resources :workspaces, param: :slug, only: [:new, :create, :show] do
     resources :projects, param: :slug, only: [:index, :show, :new, :create]
   end

   namespace :api do
     namespace :v1 do
       # Placeholders — real endpoints in later tasks
       post "prompts/:slug/resolve", to: "prompts#resolve"
       post "prompts/:slug/log",     to: "prompts#log"
     end
   end
   ```

7. `Api::V1::BaseController`:
   - No CSRF.
   - `before_action :authenticate_api_key!` (stub returning 501 Not Implemented for now — real implementation in Task 03).
   - JSON-only.

8. Dev scripts:
   - `bin/setup` — installs gems, creates DB, runs migrations, seeds.
   - `bin/dev` — starts Rails + Solid Queue via foreman (`Procfile.dev`).
   - `Procfile.dev`:
     ```
     web: bin/rails server -p 3000
     jobs: bin/jobs
     ```

9. Seed data in `db/seeds.rb`:
   - One `User` (`owner@promptly.dev`, password from env var with sensible default in dev).
   - One `Workspace` (`demo`), with that user as `owner` membership.
   - One `Project` (`playground`) under it.

10. Tests:
    - Model tests for `Workspace` (slug validation, owner relation) and `Membership` (role enum, unique user per workspace).
    - Integration test for sign-up → create workspace → land on workspace dashboard.
    - All tests green.

11. Config:
    - `config/database.yml` uses `ENV` for credentials (with dev defaults).
    - `.env.example` at repo root lists all required env vars.
    - `config/initializers/rack_attack.rb` — baseline 1000 req/min per IP on `/api`.
    - `config/initializers/secure_headers.rb` — sensible defaults for Rails + Hotwire.
    - Turbo + Stimulus work out of the box (verify with a smoke page).

## Out of scope (later tasks)

- Actual `/resolve` logic + Redis A/B router (Task 02).
- API key authentication logic (Task 03).
- The `promptly` gem — that is a separate tree in `gem/`, built later.
- UI styling beyond Rails defaults.

## PR checklist

- [ ] `bin/rails test` passes.
- [ ] `bin/rubocop` passes.
- [ ] `bin/setup` works from a clean clone.
- [ ] `bin/dev` boots web + jobs.
- [ ] PR description lists every gem added and why.
- [ ] No code comments or variable names in Spanish.
- [ ] README updated with local-dev instructions.
