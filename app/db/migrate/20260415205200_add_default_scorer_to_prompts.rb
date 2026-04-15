class AddDefaultScorerToPrompts < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_reference :prompts, :default_scorer, null: true, index: { algorithm: :concurrently }
    add_foreign_key :prompts, :scorers, column: :default_scorer_id, validate: false
  end
end
