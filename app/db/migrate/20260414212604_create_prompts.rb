class CreatePrompts < ActiveRecord::Migration[8.1]
  def change
    create_table :prompts do |t|
      t.references :project, null: false, foreign_key: true
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end

    add_index :prompts, [ :project_id, :slug ], unique: true
  end
end
