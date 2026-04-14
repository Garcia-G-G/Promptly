# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_14_215826) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key_digest", null: false
    t.string "key_prefix", null: false
    t.datetime "last_used_at"
    t.string "name", null: false
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["key_digest"], name: "index_api_keys_on_key_digest", unique: true
    t.index ["workspace_id"], name: "index_api_keys_on_workspace_id"
  end

  create_table "experiments", force: :cascade do |t|
    t.float "auto_rollback_threshold"
    t.integer "canary_stage"
    t.datetime "concluded_at"
    t.datetime "created_at", null: false
    t.string "environment", default: "production", null: false
    t.string "name", null: false
    t.bigint "prompt_id", null: false
    t.datetime "started_at"
    t.string "status", default: "draft", null: false
    t.integer "traffic_split", default: 50, null: false
    t.datetime "updated_at", null: false
    t.bigint "variant_a_version_id", null: false
    t.bigint "variant_b_version_id", null: false
    t.bigint "winner_version_id"
    t.index ["prompt_id", "environment"], name: "idx_experiments_one_running_per_prompt_env", unique: true, where: "((status)::text = 'running'::text)"
    t.index ["prompt_id", "name"], name: "index_experiments_on_prompt_id_and_name", unique: true
    t.index ["prompt_id"], name: "index_experiments_on_prompt_id"
    t.index ["variant_a_version_id"], name: "index_experiments_on_variant_a_version_id"
    t.index ["variant_b_version_id"], name: "index_experiments_on_variant_b_version_id"
    t.index ["winner_version_id"], name: "index_experiments_on_winner_version_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", default: "developer", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "workspace_id", null: false
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.index ["workspace_id", "user_id"], name: "index_memberships_on_workspace_id_and_user_id", unique: true
    t.index ["workspace_id"], name: "index_memberships_on_workspace_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.bigint "workspace_id", null: false
    t.index ["workspace_id", "slug"], name: "index_projects_on_workspace_id_and_slug", unique: true
    t.index ["workspace_id"], name: "index_projects_on_workspace_id"
  end

  create_table "prompt_versions", force: :cascade do |t|
    t.text "content", null: false
    t.string "content_hash", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "created_via", default: "api", null: false
    t.string "environment", default: "dev", null: false
    t.string "model_hint", default: "claude-sonnet-4-6", null: false
    t.bigint "parent_version_id"
    t.bigint "prompt_id", null: false
    t.datetime "updated_at", null: false
    t.jsonb "variables", default: [], null: false
    t.integer "version_number", null: false
    t.index ["created_by_id"], name: "index_prompt_versions_on_created_by_id"
    t.index ["parent_version_id"], name: "index_prompt_versions_on_parent_version_id"
    t.index ["prompt_id", "environment"], name: "idx_prompt_versions_one_active_per_env", unique: true, where: "((environment)::text <> 'archived'::text)"
    t.index ["prompt_id", "version_number"], name: "index_prompt_versions_on_prompt_id_and_version_number", unique: true
    t.index ["prompt_id"], name: "index_prompt_versions_on_prompt_id"
  end

  create_table "prompts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "project_id", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "slug"], name: "index_prompts_on_project_id_and_slug", unique: true
    t.index ["project_id"], name: "index_prompts_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "workspaces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.string "plan", default: "starter", null: false
    t.string "slug", null: false
    t.string "stripe_customer_id"
    t.string "stripe_meter_id"
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_workspaces_on_owner_id"
    t.index ["slug"], name: "index_workspaces_on_slug", unique: true
  end

  add_foreign_key "api_keys", "workspaces"
  add_foreign_key "experiments", "prompt_versions", column: "variant_a_version_id"
  add_foreign_key "experiments", "prompt_versions", column: "variant_b_version_id"
  add_foreign_key "experiments", "prompt_versions", column: "winner_version_id"
  add_foreign_key "experiments", "prompts"
  add_foreign_key "memberships", "users"
  add_foreign_key "memberships", "workspaces"
  add_foreign_key "projects", "workspaces"
  add_foreign_key "prompt_versions", "prompt_versions", column: "parent_version_id"
  add_foreign_key "prompt_versions", "prompts"
  add_foreign_key "prompt_versions", "users", column: "created_by_id"
  add_foreign_key "prompts", "projects"
  add_foreign_key "workspaces", "users", column: "owner_id"
end
