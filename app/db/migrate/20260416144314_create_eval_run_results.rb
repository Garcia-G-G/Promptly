class CreateEvalRunResults < ActiveRecord::Migration[8.1]
  def change
    create_table :eval_run_results do |t|
      t.references :eval_run, null: false, foreign_key: true
      t.references :dataset_row, null: false, foreign_key: true
      t.text :output
      t.float :score
      t.text :score_rationale
      t.integer :latency_ms
      t.text :error_message
      t.datetime :created_at, null: false
    end
  end
end
