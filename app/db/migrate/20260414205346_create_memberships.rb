class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.references :workspace, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "developer"

      t.timestamps
    end

    add_index :memberships, [ :workspace_id, :user_id ], unique: true
  end
end
