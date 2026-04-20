class CreateScorers < ActiveRecord::Migration[8.1]
  def change
    create_table :scorers do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :scorer_type, null: false, default: "llm_judge"
      t.text :content
      t.string :model_hint, null: false, default: "claude-sonnet-4-6"
      t.integer :version_number, null: false, default: 1
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :scorers, [ :project_id, :name ], unique: true
  end
end
