class CreateSecurityScans < ActiveRecord::Migration[8.1]
  def change
    create_table :security_scans do |t|
      t.references :prompt_version, null: false, foreign_key: true
      t.string :status, null: false, default: "queued"
      t.jsonb :findings, null: false, default: []
      t.datetime :started_at
      t.datetime :finished_at
      t.timestamps
    end
  end
end
