class CreateWorkspaces < ActiveRecord::Migration[8.1]
  def change
    create_table :workspaces do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :plan, null: false, default: "starter"
      t.string :stripe_customer_id
      t.string :stripe_meter_id
      t.references :owner, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :workspaces, :slug, unique: true
  end
end
