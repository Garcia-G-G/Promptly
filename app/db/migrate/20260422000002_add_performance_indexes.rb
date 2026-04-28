class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Running experiments are read on almost every dashboard page and on
    # every resolve-with-experiment call; a partial index on the hot
    # state keeps that query off a sequential scan of the whole table.
    add_index :experiments, [ :status, :environment ],
      where: "status = 'running'",
      name: "index_experiments_on_running_status",
      if_not_exists: true,
      algorithm: :concurrently

    # Aggregate queries on experiment_results always filter score IS NOT NULL
    # and group by variant; a partial composite matches that shape.
    add_index :experiment_results, [ :experiment_id, :variant, :score ],
      where: "score IS NOT NULL",
      name: "index_experiment_results_on_scored",
      if_not_exists: true,
      algorithm: :concurrently

    # Logs UI filters by project + time window + score bucket together.
    add_index :logs, [ :project_id, :created_at, :score ],
      where: "score IS NOT NULL",
      name: "index_logs_on_project_time_score",
      if_not_exists: true,
      algorithm: :concurrently

    # GIN indexes for future jsonb-key filtering on input variables.
    add_index :dataset_rows, :input_vars, using: :gin, if_not_exists: true,
      algorithm: :concurrently
    add_index :logs, :input_vars, using: :gin, if_not_exists: true,
      algorithm: :concurrently
  end
end
