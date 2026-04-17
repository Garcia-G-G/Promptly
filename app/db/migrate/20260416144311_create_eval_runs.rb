class CreateEvalRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :eval_runs do |t|
      t.references :prompt_version, null: false, foreign_key: true
      t.references :dataset, null: false, foreign_key: true
      t.references :scorer, null: false, foreign_key: true
      t.string :status, null: false, default: "queued"
      t.float :aggregate_score
      t.float :pass_rate
      t.float :pass_threshold, null: false, default: 0.6
      t.integer :total_rows, null: false, default: 0
      t.integer :scored_rows, null: false, default: 0
      t.datetime :started_at
      t.datetime :finished_at
      t.text :error_message
      t.timestamps
    end
  end
end
