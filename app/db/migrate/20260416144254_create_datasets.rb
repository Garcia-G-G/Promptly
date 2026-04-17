class CreateDatasets < ActiveRecord::Migration[8.1]
  def change
    create_table :datasets do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
    add_index :datasets, [ :project_id, :name ], unique: true
  end
end
