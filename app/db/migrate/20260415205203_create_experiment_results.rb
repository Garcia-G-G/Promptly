class CreateExperimentResults < ActiveRecord::Migration[8.1]
  def change
    create_table :experiment_results do |t|
      t.references :experiment, null: false, foreign_key: true
      t.references :log, null: false, foreign_key: true
      t.string :variant, null: false
      t.float :score

      t.datetime :created_at, null: false
    end

    add_index :experiment_results, [ :experiment_id, :variant, :created_at ],
      name: "idx_experiment_results_variant"
  end
end
