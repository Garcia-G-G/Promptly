class CreateDatasetRows < ActiveRecord::Migration[8.1]
  def change
    create_table :dataset_rows do |t|
      t.references :dataset, null: false, foreign_key: true
      t.jsonb :input_vars, null: false, default: {}
      t.text :expected_output
      t.jsonb :tags, null: false, default: []
      t.timestamps
    end
  end
end
