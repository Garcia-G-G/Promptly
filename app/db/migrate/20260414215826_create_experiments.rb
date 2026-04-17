class CreateExperiments < ActiveRecord::Migration[8.1]
  def change
    create_table :experiments do |t|
      t.references :prompt, null: false, foreign_key: true
      t.string :name, null: false
      t.string :status, null: false, default: "draft"
      t.references :variant_a_version, null: false, foreign_key: { to_table: :prompt_versions }
      t.references :variant_b_version, null: false, foreign_key: { to_table: :prompt_versions }
      t.integer :traffic_split, null: false, default: 50
      t.string :environment, null: false, default: "production"
      t.integer :canary_stage
      t.float :auto_rollback_threshold
      t.references :winner_version, null: true, foreign_key: { to_table: :prompt_versions }
      t.datetime :started_at
      t.datetime :concluded_at

      t.timestamps
    end

    add_index :experiments, [ :prompt_id, :name ], unique: true
    add_index :experiments, [ :prompt_id, :environment ],
      unique: true,
      where: "status = 'running'",
      name: "idx_experiments_one_running_per_prompt_env"
  end
end
