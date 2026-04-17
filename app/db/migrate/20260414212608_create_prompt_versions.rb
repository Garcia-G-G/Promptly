class CreatePromptVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :prompt_versions do |t|
      t.references :prompt, null: false, foreign_key: true
      t.integer :version_number, null: false
      t.text :content, null: false
      t.jsonb :variables, null: false, default: []
      t.string :model_hint, null: false, default: "claude-sonnet-4-6"
      t.string :environment, null: false, default: "dev"
      t.string :content_hash, null: false
      t.references :parent_version, null: true, foreign_key: { to_table: :prompt_versions }
      t.references :created_by, null: true, foreign_key: { to_table: :users }
      t.string :created_via, null: false, default: "api"

      t.timestamps
    end

    add_index :prompt_versions, [ :prompt_id, :version_number ], unique: true
    add_index :prompt_versions, [ :prompt_id, :environment ],
      unique: true,
      where: "environment != 'archived'",
      name: "idx_prompt_versions_one_active_per_env"
  end
end
