class CreateLogs < ActiveRecord::Migration[8.1]
  def change
    # Note: Consider partitioning by created_at month at > 10M rows
    create_table :logs do |t|
      t.references :prompt, null: false, foreign_key: true
      t.references :prompt_version, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :request_id
      t.jsonb :input_vars, null: false, default: {}
      t.text :output, null: false
      t.integer :latency_ms
      t.jsonb :tokens, null: false, default: {}
      t.string :model_version
      t.references :experiment, null: true, foreign_key: true
      t.string :variant
      t.float :score
      t.text :score_rationale
      t.references :scorer, null: true, foreign_key: true
      t.string :otel_trace_id
      t.string :otel_span_id

      t.datetime :created_at, null: false
    end

    add_index :logs, [ :prompt_id, :created_at ]
    add_index :logs, [ :experiment_id, :variant, :created_at ],
      where: "experiment_id IS NOT NULL",
      name: "idx_logs_experiment_variant"
    add_index :logs, :request_id,
      where: "request_id IS NOT NULL",
      name: "idx_logs_request_id"
  end
end
