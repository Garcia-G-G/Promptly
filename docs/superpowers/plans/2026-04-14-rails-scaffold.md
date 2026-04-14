# Rails 8 App Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the Rails 8 foundation for Promptly — Devise auth, multi-tenant models (Workspace, Membership, Project, ApiKey), web + API controllers, dev scripts, seeds, and tests.

**Architecture:** Monorepo with Rails app in `app/`. Thin controllers, business logic in services (future tasks). Multi-tenancy via Workspace scoping with Membership-based access control. API layer separated from web layer with its own base controller.

**Tech Stack:** Rails 8.1, Ruby 3.3, PostgreSQL 14, Redis 8, Devise, Solid Queue/Cache/Cable, Hotwire

**Spec:** `docs/superpowers/specs/2026-04-14-rails-scaffold-design.md`

---

## File Structure

```
app/                              # Rails 8 application root
  app/
    controllers/
      application_controller.rb   # Modify: add current_workspace, authenticate
      marketing_controller.rb     # Create: public landing page
      workspaces_controller.rb    # Create: CRUD for workspaces
      projects_controller.rb      # Create: CRUD for projects (nested)
      api/v1/
        base_controller.rb        # Create: API base with stub auth
        prompts_controller.rb     # Create: placeholder resolve/log
    models/
      user.rb                     # Modify: Devise + normalizes
      workspace.rb                # Create: multi-tenant root
      membership.rb               # Create: user-workspace join
      project.rb                  # Create: prompt container
      api_key.rb                  # Create: API authentication
    views/
      marketing/index.html.erb    # Create: landing page
      workspaces/
        new.html.erb              # Create: workspace form
        show.html.erb             # Create: workspace dashboard
      projects/
        index.html.erb            # Create: project list
        show.html.erb             # Create: project detail
        new.html.erb              # Create: project form
  config/
    database.yml                  # Modify: ENV-based config
    routes.rb                     # Modify: all routes
    initializers/
      rack_attack.rb              # Create: API rate limiting
      secure_headers.rb           # Create: HSTS/CSP
      strong_migrations.rb        # Create: auto-generated
  db/
    migrate/
      *_devise_create_users.rb    # Create: Devise migration
      *_add_name_to_users.rb      # Create: name column
      *_create_workspaces.rb      # Create: workspace table
      *_create_memberships.rb     # Create: membership table
      *_create_projects.rb        # Create: project table
      *_create_api_keys.rb        # Create: api_key table
    seeds.rb                      # Modify: demo data
  test/
    models/
      workspace_test.rb           # Create: workspace validations
      membership_test.rb          # Create: membership validations
    controllers/
      api/v1/
        base_controller_test.rb   # Create: API stub test
    integration/
      signup_flow_test.rb         # Create: end-to-end signup
  Procfile.dev                    # Create: web + jobs
  Gemfile                         # Modify: add gems
```

---

### Task 1: Generate Rails 8 App

**Files:**
- Create: `app/` (entire Rails skeleton)

- [ ] **Step 1: Initialize git in the repo root**

```bash
cd /Users/go/Promptly
git init
git add CONTEXT.md CLAUDE.md README.md .gitignore .env.example docs/ prompts/
git commit -m "chore: initial repo structure with project docs"
```

- [ ] **Step 2: Generate the Rails app**

```bash
cd /Users/go/Promptly
rails new app --database=postgresql --skip-jbuilder --skip-git --name=Promptly
```

Expected: Rails 8 app created in `app/` with Propshaft, Importmap, Turbo, Stimulus, Solid Queue/Cache/Cable.

- [ ] **Step 3: Verify the app boots**

```bash
cd /Users/go/Promptly/app
bundle install
bin/rails db:create
bin/rails server -p 3000 &
sleep 3
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
kill %1
```

Expected: HTTP 200 (Rails welcome page).

- [ ] **Step 4: Commit**

```bash
cd /Users/go/Promptly
git add app/
git commit -m "chore: generate Rails 8 app with postgresql, solid stack"
```

---

### Task 2: Add Gem Dependencies

**Files:**
- Modify: `app/Gemfile`

- [ ] **Step 1: Add production gems to Gemfile**

Add after the existing gem declarations in `app/Gemfile`:

```ruby
# Authentication
gem "devise"

# External services
gem "stripe"
gem "octokit"
gem "anthropic"

# Observability
gem "opentelemetry-sdk"
gem "opentelemetry-instrumentation-rails"

# Security & rate limiting
gem "rack-attack"
gem "secure_headers"

# Redis (A/B router only — not for jobs/cache/cable)
gem "redis"

# Database safety
gem "strong_migrations"

# Solid Queue dashboard
gem "mission_control-jobs"
```

- [ ] **Step 2: Add dev/test gems**

Add to the `group :development, :test` block in `app/Gemfile`:

```ruby
gem "dotenv-rails"
gem "faker"
gem "rubocop-minitest", require: false
```

- [ ] **Step 3: Bundle install**

```bash
cd /Users/go/Promptly/app
bundle install
```

Expected: All gems resolve and install without conflicts.

- [ ] **Step 4: Commit**

```bash
cd /Users/go/Promptly
git add app/Gemfile app/Gemfile.lock
git commit -m "chore: add gem dependencies (devise, stripe, redis, otel, etc.)"
```

---

### Task 3: Configure Devise + User Model

**Files:**
- Modify: `app/app/models/user.rb`
- Create: `app/db/migrate/*_devise_create_users.rb` (generated)
- Create: `app/db/migrate/*_add_name_to_users.rb`
- Create: `app/config/initializers/devise.rb` (generated)
- Modify: `app/config/routes.rb`

- [ ] **Step 1: Run Devise installer**

```bash
cd /Users/go/Promptly/app
bin/rails generate devise:install
```

Expected: Creates `config/initializers/devise.rb` and prints setup instructions.

- [ ] **Step 2: Configure Devise initializer for development**

In `app/config/initializers/devise.rb`, ensure these settings:

```ruby
config.mailer_sender = "noreply@promptly.dev"
```

In `app/config/environments/development.rb`, add:

```ruby
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```

In `app/config/environments/test.rb`, add:

```ruby
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```

- [ ] **Step 3: Generate User model with Devise**

```bash
cd /Users/go/Promptly/app
bin/rails generate devise User
```

Expected: Creates migration and `app/models/user.rb`.

- [ ] **Step 4: Enable confirmable in the migration**

Open the generated Devise migration. Uncomment the `## Confirmable` section:

```ruby
## Confirmable
t.string   :confirmation_token
t.datetime :confirmed_at
t.datetime :confirmation_sent_at
t.string   :unconfirmed_email
```

And uncomment the confirmable index:

```ruby
add_index :users, :confirmation_token, unique: true
```

- [ ] **Step 5: Add name column migration**

```bash
cd /Users/go/Promptly/app
bin/rails generate migration AddNameToUsers name:string
```

- [ ] **Step 6: Update User model**

Replace `app/app/models/user.rb` with:

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  normalizes :email, with: -> { _1.strip.downcase }

  has_many :memberships, dependent: :destroy
  has_many :workspaces, through: :memberships
  has_many :owned_workspaces, class_name: "Workspace", foreign_key: :owner_id, dependent: :nullify
end
```

- [ ] **Step 7: Run migrations**

```bash
cd /Users/go/Promptly/app
bin/rails db:migrate
```

Expected: Both migrations run successfully.

- [ ] **Step 8: Commit**

```bash
cd /Users/go/Promptly
git add app/app/models/user.rb app/db/ app/config/
git commit -m "feat: add Devise auth with User model (confirmable, name field)"
```

---

### Task 4: Create Workspace Model

**Files:**
- Create: `app/db/migrate/*_create_workspaces.rb`
- Create: `app/app/models/workspace.rb`
- Test: `app/test/models/workspace_test.rb`

- [ ] **Step 1: Write the failing test**

Create `app/test/models/workspace_test.rb`:

```ruby
require "test_helper"

class WorkspaceTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(
      email: "owner@test.com",
      password: "password123456",
      name: "Test Owner"
    )
    @owner.confirm
  end

  test "valid workspace" do
    workspace = Workspace.new(name: "My Workspace", slug: "my-workspace", owner: @owner)
    assert workspace.valid?
  end

  test "requires slug" do
    workspace = Workspace.new(name: "My Workspace", slug: nil, owner: @owner)
    assert_not workspace.valid?
    assert_includes workspace.errors[:slug], "can't be blank"
  end

  test "requires unique slug" do
    Workspace.create!(name: "First", slug: "taken", owner: @owner)
    workspace = Workspace.new(name: "Second", slug: "taken", owner: @owner)
    assert_not workspace.valid?
    assert_includes workspace.errors[:slug], "has already been taken"
  end

  test "slug format allows lowercase alphanumeric and hyphens" do
    valid_slugs = %w[my-workspace workspace1 a-b-c-123]
    valid_slugs.each do |slug|
      workspace = Workspace.new(name: "Test", slug: slug, owner: @owner)
      assert workspace.valid?, "Expected '#{slug}' to be valid"
    end
  end

  test "slug format rejects invalid characters" do
    invalid_slugs = ["My Workspace", "UPPER", "under_score", "special!", "slug with spaces"]
    invalid_slugs.each do |slug|
      workspace = Workspace.new(name: "Test", slug: slug, owner: @owner)
      assert_not workspace.valid?, "Expected '#{slug}' to be invalid"
    end
  end

  test "normalizes slug to lowercase" do
    workspace = Workspace.new(name: "Test", slug: "  my-slug  ", owner: @owner)
    assert_equal "my-slug", workspace.slug
  end

  test "belongs to owner" do
    workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
    assert_equal @owner, workspace.owner
  end

  test "has many memberships" do
    workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
    assert_respond_to workspace, :memberships
  end

  test "has many projects" do
    workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
    assert_respond_to workspace, :projects
  end

  test "has many api_keys" do
    workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
    assert_respond_to workspace, :api_keys
  end

  test "default plan is starter" do
    workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
    assert_equal "starter", workspace.plan
  end

  test "destroys memberships on delete" do
    workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
    Membership.create!(workspace: workspace, user: @owner, role: :owner)
    assert_difference "Membership.count", -1 do
      workspace.destroy
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/go/Promptly/app
bin/rails test test/models/workspace_test.rb
```

Expected: FAIL — `Workspace` class not found.

- [ ] **Step 3: Generate migration**

```bash
cd /Users/go/Promptly/app
bin/rails generate migration CreateWorkspaces \
  name:string \
  slug:string \
  plan:string \
  stripe_customer_id:string \
  stripe_meter_id:string
```

Then edit the generated migration to add the owner reference, defaults, and index:

```ruby
class CreateWorkspaces < ActiveRecord::Migration[8.0]
  def change
    create_table :workspaces do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :plan, null: false, default: "starter"
      t.string :stripe_customer_id
      t.string :stripe_meter_id
      t.references :owner, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :workspaces, :slug, unique: true
  end
end
```

- [ ] **Step 4: Create Workspace model**

Create `app/app/models/workspace.rb`:

```ruby
class Workspace < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :projects, dependent: :destroy
  has_many :api_keys, dependent: :destroy

  normalizes :slug, with: -> { _1.strip.downcase }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }
end
```

- [ ] **Step 5: Run migration and tests**

```bash
cd /Users/go/Promptly/app
bin/rails db:migrate
bin/rails test test/models/workspace_test.rb
```

Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/go/Promptly
git add app/app/models/workspace.rb app/db/migrate/ app/test/models/workspace_test.rb app/db/schema.rb
git commit -m "feat: add Workspace model with slug validation and owner association"
```

---

### Task 5: Create Membership Model

**Files:**
- Create: `app/db/migrate/*_create_memberships.rb`
- Create: `app/app/models/membership.rb`
- Test: `app/test/models/membership_test.rb`

- [ ] **Step 1: Write the failing test**

Create `app/test/models/membership_test.rb`:

```ruby
require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(
      email: "owner@test.com",
      password: "password123456",
      name: "Test Owner"
    )
    @owner.confirm
    @workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
  end

  test "valid membership" do
    membership = Membership.new(workspace: @workspace, user: @owner, role: :owner)
    assert membership.valid?
  end

  test "valid roles" do
    %w[owner admin developer viewer].each do |role|
      membership = Membership.new(workspace: @workspace, user: @owner, role: role)
      assert membership.valid?, "Expected role '#{role}' to be valid"
    end
  end

  test "rejects invalid role" do
    assert_raises ArgumentError do
      Membership.new(workspace: @workspace, user: @owner, role: :superadmin)
    end
  end

  test "unique user per workspace" do
    Membership.create!(workspace: @workspace, user: @owner, role: :owner)
    duplicate = Membership.new(workspace: @workspace, user: @owner, role: :developer)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "same user can be in different workspaces" do
    other_workspace = Workspace.create!(name: "Other", slug: "other", owner: @owner)
    Membership.create!(workspace: @workspace, user: @owner, role: :owner)
    membership = Membership.new(workspace: other_workspace, user: @owner, role: :owner)
    assert membership.valid?
  end

  test "belongs to workspace" do
    membership = Membership.create!(workspace: @workspace, user: @owner, role: :owner)
    assert_equal @workspace, membership.workspace
  end

  test "belongs to user" do
    membership = Membership.create!(workspace: @workspace, user: @owner, role: :owner)
    assert_equal @owner, membership.user
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/go/Promptly/app
bin/rails test test/models/membership_test.rb
```

Expected: FAIL — `Membership` class not found.

- [ ] **Step 3: Generate migration**

```bash
cd /Users/go/Promptly/app
bin/rails generate migration CreateMemberships
```

Edit the migration:

```ruby
class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "developer"

      t.timestamps
    end

    add_index :memberships, [ :workspace_id, :user_id ], unique: true
  end
end
```

- [ ] **Step 4: Create Membership model**

Create `app/app/models/membership.rb`:

```ruby
class Membership < ApplicationRecord
  belongs_to :workspace
  belongs_to :user

  enum :role, { owner: "owner", admin: "admin", developer: "developer", viewer: "viewer" }

  validates :role, inclusion: { in: roles.keys }
  validates :user_id, uniqueness: { scope: :workspace_id }
end
```

- [ ] **Step 5: Run migration and tests**

```bash
cd /Users/go/Promptly/app
bin/rails db:migrate
bin/rails test test/models/membership_test.rb
```

Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/go/Promptly
git add app/app/models/membership.rb app/db/migrate/ app/test/models/membership_test.rb app/db/schema.rb
git commit -m "feat: add Membership model with role enum and unique user-workspace constraint"
```

---

### Task 6: Create Project Model

**Files:**
- Create: `app/db/migrate/*_create_projects.rb`
- Create: `app/app/models/project.rb`

- [ ] **Step 1: Generate migration**

```bash
cd /Users/go/Promptly/app
bin/rails generate migration CreateProjects
```

Edit the migration:

```ruby
class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :projects, [ :workspace_id, :slug ], unique: true
  end
end
```

- [ ] **Step 2: Create Project model**

Create `app/app/models/project.rb`:

```ruby
class Project < ApplicationRecord
  belongs_to :workspace

  normalizes :slug, with: -> { _1.strip.downcase }

  validates :name, presence: true
  validates :slug, presence: true,
    uniqueness: { scope: :workspace_id },
    format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }
end
```

- [ ] **Step 3: Run migration**

```bash
cd /Users/go/Promptly/app
bin/rails db:migrate
```

Expected: Migration runs successfully.

- [ ] **Step 4: Commit**

```bash
cd /Users/go/Promptly
git add app/app/models/project.rb app/db/migrate/ app/db/schema.rb
git commit -m "feat: add Project model with workspace-scoped slug uniqueness"
```

---

### Task 7: Create ApiKey Model

**Files:**
- Create: `app/db/migrate/*_create_api_keys.rb`
- Create: `app/app/models/api_key.rb`

- [ ] **Step 1: Generate migration**

```bash
cd /Users/go/Promptly/app
bin/rails generate migration CreateApiKeys
```

Edit the migration:

```ruby
class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :name, null: false
      t.string :key_prefix, null: false
      t.string :key_digest, null: false
      t.datetime :last_used_at
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :api_keys, :key_digest, unique: true
  end
end
```

- [ ] **Step 2: Create ApiKey model**

Create `app/app/models/api_key.rb`:

```ruby
class ApiKey < ApplicationRecord
  belongs_to :workspace

  validates :name, presence: true
  validates :key_prefix, presence: true
  validates :key_digest, presence: true, uniqueness: true

  attr_accessor :raw_key

  before_validation :generate_key, on: :create

  def self.authenticate(raw_key)
    return nil if raw_key.blank?

    # Extract workspace_id from key format: pk_{workspace_id}_{random}
    # For now, hash without workspace salt and look up by digest
    digest = Digest::SHA256.hexdigest(raw_key)
    key = find_by(key_digest: digest, revoked_at: nil)
    key&.touch(:last_used_at)
    key
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  private

  def generate_key
    return if key_digest.present?

    raw = "pk_#{SecureRandom.hex(24)}"
    self.raw_key = raw
    self.key_prefix = raw[0, 8]
    self.key_digest = Digest::SHA256.hexdigest(raw)
  end
end
```

- [ ] **Step 3: Run migration**

```bash
cd /Users/go/Promptly/app
bin/rails db:migrate
```

Expected: Migration runs successfully.

- [ ] **Step 4: Commit**

```bash
cd /Users/go/Promptly
git add app/app/models/api_key.rb app/db/migrate/ app/db/schema.rb
git commit -m "feat: add ApiKey model with SHA-256 digest and prefix for identification"
```

---

### Task 8: Routes + Marketing Controller

**Files:**
- Modify: `app/config/routes.rb`
- Create: `app/app/controllers/marketing_controller.rb`
- Create: `app/app/views/marketing/index.html.erb`

- [ ] **Step 1: Update routes**

Replace `app/config/routes.rb` with:

```ruby
Rails.application.routes.draw do
  devise_for :users

  root "marketing#index"

  resources :workspaces, param: :slug, only: [ :new, :create, :show ] do
    resources :projects, param: :slug, only: [ :index, :show, :new, :create ]
  end

  namespace :api do
    namespace :v1 do
      post "prompts/:slug/resolve", to: "prompts#resolve"
      post "prompts/:slug/log",     to: "prompts#log"
    end
  end

  mount MissionControl::Jobs::Engine, at: "/jobs" if defined?(MissionControl::Jobs)

  get "up" => "rails/health#show", as: :rails_health_check
end
```

- [ ] **Step 2: Create MarketingController**

Create `app/app/controllers/marketing_controller.rb`:

```ruby
class MarketingController < ApplicationController
  skip_before_action :authenticate_user!

  def index
  end
end
```

- [ ] **Step 3: Create landing page view**

Create `app/app/views/marketing/index.html.erb`:

```erb
<h1>Promptly</h1>
<p>Git + Vercel, but for your LLM prompts.</p>

<% if user_signed_in? %>
  <%= link_to "Dashboard", workspaces_path %>
<% else %>
  <%= link_to "Sign Up", new_user_registration_path %>
  <%= link_to "Sign In", new_user_session_path %>
<% end %>
```

- [ ] **Step 4: Commit**

```bash
cd /Users/go/Promptly
git add app/config/routes.rb app/app/controllers/marketing_controller.rb app/app/views/marketing/
git commit -m "feat: add routes and marketing landing page"
```

---

### Task 9: ApplicationController + current_workspace

**Files:**
- Modify: `app/app/controllers/application_controller.rb`

- [ ] **Step 1: Update ApplicationController**

Replace `app/app/controllers/application_controller.rb` with:

```ruby
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  helper_method :current_workspace

  private

  def current_workspace
    return @current_workspace if defined?(@current_workspace)

    slug = params[:workspace_slug] || params[:slug]
    return nil unless slug

    @current_workspace = current_user
      .workspaces
      .find_by!(slug: slug)
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Not Found"
  end
end
```

- [ ] **Step 2: Commit**

```bash
cd /Users/go/Promptly
git add app/app/controllers/application_controller.rb
git commit -m "feat: add current_workspace helper with membership-scoped access"
```

---

### Task 10: Workspaces Controller + Views

**Files:**
- Create: `app/app/controllers/workspaces_controller.rb`
- Create: `app/app/views/workspaces/new.html.erb`
- Create: `app/app/views/workspaces/show.html.erb`

- [ ] **Step 1: Create WorkspacesController**

Create `app/app/controllers/workspaces_controller.rb`:

```ruby
class WorkspacesController < ApplicationController
  def new
    @workspace = Workspace.new
  end

  def create
    @workspace = Workspace.new(workspace_params)
    @workspace.owner = current_user

    if @workspace.save
      Membership.create!(workspace: @workspace, user: current_user, role: :owner)
      redirect_to workspace_path(@workspace.slug), notice: "Workspace created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @workspace = current_workspace
    @projects = @workspace.projects.order(:name)
  end

  private

  def workspace_params
    params.require(:workspace).permit(:name, :slug)
  end
end
```

- [ ] **Step 2: Create new workspace form**

Create `app/app/views/workspaces/new.html.erb`:

```erb
<h1>Create a Workspace</h1>

<%= form_with model: @workspace do |f| %>
  <% if @workspace.errors.any? %>
    <div id="error_explanation">
      <ul>
        <% @workspace.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :name %>
    <%= f.text_field :name, required: true %>
  </div>

  <div>
    <%= f.label :slug %>
    <%= f.text_field :slug, required: true, pattern: "[a-z0-9-]+" %>
  </div>

  <div>
    <%= f.submit "Create Workspace" %>
  </div>
<% end %>
```

- [ ] **Step 3: Create workspace show page**

Create `app/app/views/workspaces/show.html.erb`:

```erb
<h1><%= @workspace.name %></h1>

<h2>Projects</h2>

<% if @projects.any? %>
  <ul>
    <% @projects.each do |project| %>
      <li>
        <%= link_to project.name, workspace_project_path(@workspace.slug, project.slug) %>
      </li>
    <% end %>
  </ul>
<% else %>
  <p>No projects yet.</p>
<% end %>

<%= link_to "New Project", new_workspace_project_path(@workspace.slug) %>
```

- [ ] **Step 4: Commit**

```bash
cd /Users/go/Promptly
git add app/app/controllers/workspaces_controller.rb app/app/views/workspaces/
git commit -m "feat: add WorkspacesController with create and show actions"
```

---

### Task 11: Projects Controller + Views

**Files:**
- Create: `app/app/controllers/projects_controller.rb`
- Create: `app/app/views/projects/index.html.erb`
- Create: `app/app/views/projects/show.html.erb`
- Create: `app/app/views/projects/new.html.erb`

- [ ] **Step 1: Create ProjectsController**

Create `app/app/controllers/projects_controller.rb`:

```ruby
class ProjectsController < ApplicationController
  before_action :set_workspace

  def index
    @projects = @workspace.projects.order(:name)
  end

  def show
    @project = @workspace.projects.find_by!(slug: params[:slug])
  end

  def new
    @project = @workspace.projects.build
  end

  def create
    @project = @workspace.projects.build(project_params)

    if @project.save
      redirect_to workspace_project_path(@workspace.slug, @project.slug), notice: "Project created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_workspace
    @workspace = current_workspace
  end

  def project_params
    params.require(:project).permit(:name, :slug)
  end
end
```

- [ ] **Step 2: Create project views**

Create `app/app/views/projects/index.html.erb`:

```erb
<h1>Projects in <%= @workspace.name %></h1>

<% if @projects.any? %>
  <ul>
    <% @projects.each do |project| %>
      <li>
        <%= link_to project.name, workspace_project_path(@workspace.slug, project.slug) %>
      </li>
    <% end %>
  </ul>
<% else %>
  <p>No projects yet.</p>
<% end %>

<%= link_to "New Project", new_workspace_project_path(@workspace.slug) %>
```

Create `app/app/views/projects/show.html.erb`:

```erb
<h1><%= @project.name %></h1>
<p>Workspace: <%= @workspace.name %></p>
<p>Slug: <code><%= @project.slug %></code></p>

<%= link_to "Back to Projects", workspace_projects_path(@workspace.slug) %>
```

Create `app/app/views/projects/new.html.erb`:

```erb
<h1>New Project in <%= @workspace.name %></h1>

<%= form_with model: @project, url: workspace_projects_path(@workspace.slug) do |f| %>
  <% if @project.errors.any? %>
    <div id="error_explanation">
      <ul>
        <% @project.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :name %>
    <%= f.text_field :name, required: true %>
  </div>

  <div>
    <%= f.label :slug %>
    <%= f.text_field :slug, required: true, pattern: "[a-z0-9-]+" %>
  </div>

  <div>
    <%= f.submit "Create Project" %>
  </div>
<% end %>
```

- [ ] **Step 3: Commit**

```bash
cd /Users/go/Promptly
git add app/app/controllers/projects_controller.rb app/app/views/projects/
git commit -m "feat: add ProjectsController with CRUD actions and views"
```

---

### Task 12: API Base Controller + Prompts Placeholder

**Files:**
- Create: `app/app/controllers/api/v1/base_controller.rb`
- Create: `app/app/controllers/api/v1/prompts_controller.rb`
- Test: `app/test/controllers/api/v1/base_controller_test.rb`

- [ ] **Step 1: Write the failing test**

Create `app/test/controllers/api/v1/base_controller_test.rb`:

```ruby
require "test_helper"

class Api::V1::PromptsControllerTest < ActionDispatch::IntegrationTest
  test "resolve returns 501 without authentication" do
    post api_v1_prompt_resolve_path(slug: "test-prompt")
    assert_response :not_implemented
    assert_equal "application/json", response.media_type

    body = JSON.parse(response.body)
    assert_equal "not_implemented", body["status"]
  end

  test "log returns 501 without authentication" do
    post api_v1_prompt_log_path(slug: "test-prompt")
    assert_response :not_implemented
    assert_equal "application/json", response.media_type

    body = JSON.parse(response.body)
    assert_equal "not_implemented", body["status"]
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/go/Promptly/app
bin/rails test test/controllers/api/v1/base_controller_test.rb
```

Expected: FAIL — controllers not found.

- [ ] **Step 3: Create API directory structure**

```bash
mkdir -p /Users/go/Promptly/app/app/controllers/api/v1
```

- [ ] **Step 4: Create Api::V1::BaseController**

Create `app/app/controllers/api/v1/base_controller.rb`:

```ruby
module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_key!

      private

      def authenticate_api_key!
        render json: { status: "not_implemented", error: "API key authentication not yet implemented" }, status: :not_implemented
      end
    end
  end
end
```

- [ ] **Step 5: Create Api::V1::PromptsController**

Create `app/app/controllers/api/v1/prompts_controller.rb`:

```ruby
module Api
  module V1
    class PromptsController < BaseController
      def resolve
        render json: { status: "not_implemented" }, status: :not_implemented
      end

      def log
        render json: { status: "not_implemented" }, status: :not_implemented
      end
    end
  end
end
```

- [ ] **Step 6: Update routes with named helpers**

Verify the routes in `app/config/routes.rb` generate the correct path helpers. Update the API routes to use explicit `as:` if needed:

```ruby
namespace :api do
  namespace :v1 do
    post "prompts/:slug/resolve", to: "prompts#resolve", as: :prompt_resolve
    post "prompts/:slug/log",     to: "prompts#log",     as: :prompt_log
  end
end
```

- [ ] **Step 7: Run tests**

```bash
cd /Users/go/Promptly/app
bin/rails test test/controllers/api/v1/base_controller_test.rb
```

Expected: All tests PASS.

- [ ] **Step 8: Commit**

```bash
cd /Users/go/Promptly
git add app/app/controllers/api/ app/test/controllers/ app/config/routes.rb
git commit -m "feat: add API v1 base controller with 501 auth stub and prompts placeholder"
```

---

### Task 13: Initializers (Rack::Attack, SecureHeaders, StrongMigrations)

**Files:**
- Create: `app/config/initializers/rack_attack.rb`
- Create: `app/config/initializers/secure_headers.rb`
- Create: `app/config/initializers/strong_migrations.rb`

- [ ] **Step 1: Create Rack::Attack config**

Create `app/config/initializers/rack_attack.rb`:

```ruby
class Rack::Attack
  throttle("api/ip", limit: 1000, period: 60) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  throttle("login/ip", limit: 20, period: 60) do |req|
    req.ip if req.path == "/users/sign_in" && req.post?
  end
end
```

- [ ] **Step 2: Create SecureHeaders config**

Create `app/config/initializers/secure_headers.rb`:

```ruby
SecureHeaders::Configuration.default do |config|
  config.hsts = "max-age=631138519; includeSubDomains"
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "0"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = %w[strict-origin-when-cross-origin]

  config.csp = {
    default_src: %w['self'],
    script_src: %w['self' 'unsafe-inline'],
    style_src: %w['self' 'unsafe-inline'],
    connect_src: %w['self' ws://localhost:* wss://localhost:*],
    img_src: %w['self' data:],
    font_src: %w['self'],
    frame_ancestors: %w['none'],
    form_action: %w['self'],
    base_uri: %w['self']
  }
end
```

- [ ] **Step 3: Generate StrongMigrations config**

```bash
cd /Users/go/Promptly/app
bin/rails generate strong_migrations:install
```

Expected: Creates `config/initializers/strong_migrations.rb`.

- [ ] **Step 4: Commit**

```bash
cd /Users/go/Promptly
git add app/config/initializers/rack_attack.rb app/config/initializers/secure_headers.rb app/config/initializers/strong_migrations.rb
git commit -m "chore: add Rack::Attack, SecureHeaders, and StrongMigrations config"
```

---

### Task 14: Database Config + Dev Scripts

**Files:**
- Modify: `app/config/database.yml`
- Modify: `app/bin/setup`
- Create: `app/Procfile.dev`

- [ ] **Step 1: Update database.yml**

Replace `app/config/database.yml` with:

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: promptly_development
  url: <%= ENV["DATABASE_URL"] %>

test:
  <<: *default
  database: promptly_test

production:
  <<: *default
  url: <%= ENV["DATABASE_URL"] %>
```

- [ ] **Step 2: Create Procfile.dev**

Create `app/Procfile.dev`:

```
web: bin/rails server -p 3000
jobs: bin/jobs
```

- [ ] **Step 3: Verify bin/setup works**

```bash
cd /Users/go/Promptly/app
bin/setup
```

Expected: Installs gems, creates DB, runs migrations, seeds.

- [ ] **Step 4: Verify bin/dev boots**

```bash
cd /Users/go/Promptly/app
bin/dev &
sleep 5
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
kill %1 2>/dev/null
```

Expected: HTTP 200.

- [ ] **Step 5: Commit**

```bash
cd /Users/go/Promptly
git add app/config/database.yml app/Procfile.dev
git commit -m "chore: configure database.yml with ENV support and Procfile.dev"
```

---

### Task 15: Seeds

**Files:**
- Modify: `app/db/seeds.rb`

- [ ] **Step 1: Write seeds**

Replace `app/db/seeds.rb` with:

```ruby
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

Project.find_or_create_by!(workspace: workspace, slug: "playground") do |p|
  p.name = "Playground"
end

puts "Seeding complete."
puts "  Owner: #{owner.email}"
puts "  Workspace: #{workspace.slug}"
puts "  Project: playground"
```

- [ ] **Step 2: Run seeds**

```bash
cd /Users/go/Promptly/app
bin/rails db:seed
```

Expected: Prints seed summary. No errors.

- [ ] **Step 3: Verify in console**

```bash
cd /Users/go/Promptly/app
bin/rails runner "puts User.count, Workspace.count, Project.count"
```

Expected: `1`, `1`, `1`.

- [ ] **Step 4: Commit**

```bash
cd /Users/go/Promptly
git add app/db/seeds.rb
git commit -m "feat: add seed data (demo owner, workspace, project)"
```

---

### Task 16: Integration Test — Signup Flow

**Files:**
- Test: `app/test/integration/signup_flow_test.rb`

- [ ] **Step 1: Write the integration test**

Create `app/test/integration/signup_flow_test.rb`:

```ruby
require "test_helper"

class SignupFlowTest < ActionDispatch::IntegrationTest
  test "signup, confirm, create workspace, see workspace dashboard" do
    # Sign up
    get new_user_registration_path
    assert_response :success

    post user_registration_path, params: {
      user: {
        email: "newuser@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123",
        name: "New User"
      }
    }
    assert_response :redirect

    # Confirm the user
    user = User.find_by(email: "newuser@example.com")
    assert user.present?
    user.confirm

    # Sign in
    post user_session_path, params: {
      user: {
        email: "newuser@example.com",
        password: "securepassword123"
      }
    }
    assert_response :redirect

    # Create a workspace
    post workspaces_path, params: {
      workspace: {
        name: "My Workspace",
        slug: "my-workspace"
      }
    }
    assert_response :redirect
    follow_redirect!

    # Should be on the workspace dashboard
    assert_response :success
    assert_select "h1", "My Workspace"
  end
end
```

- [ ] **Step 2: Run the integration test**

```bash
cd /Users/go/Promptly/app
bin/rails test test/integration/signup_flow_test.rb
```

Expected: PASS.

- [ ] **Step 3: Run the full test suite**

```bash
cd /Users/go/Promptly/app
bin/rails test
```

Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
cd /Users/go/Promptly
git add app/test/integration/signup_flow_test.rb
git commit -m "test: add signup flow integration test"
```

---

### Task 17: Rubocop + Final Verification

**Files:**
- Modify: `app/.rubocop.yml` (if needed)

- [ ] **Step 1: Run Rubocop**

```bash
cd /Users/go/Promptly/app
bin/rubocop
```

If there are offenses, fix them. Common issues:
- Line length in generated files
- Missing frozen string literal comments
- Style preferences from omakase

- [ ] **Step 2: Run full test suite again**

```bash
cd /Users/go/Promptly/app
bin/rails test
```

Expected: All tests PASS.

- [ ] **Step 3: Verify the app boots cleanly**

```bash
cd /Users/go/Promptly/app
bin/dev &
sleep 5
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000
kill %1 2>/dev/null
```

Expected: HTTP 200.

- [ ] **Step 4: Final commit if any rubocop fixes were made**

```bash
cd /Users/go/Promptly
git add app/
git commit -m "chore: fix rubocop offenses"
```

- [ ] **Step 5: Verify all commits**

```bash
cd /Users/go/Promptly
git log --oneline
```

Expected: Clean sequential commits following conventional commit style.
