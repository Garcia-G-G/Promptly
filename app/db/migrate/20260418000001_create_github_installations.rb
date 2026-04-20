class CreateGithubInstallations < ActiveRecord::Migration[8.1]
  def change
    create_table :github_installations do |t|
      t.references :workspace, null: false, foreign_key: true
      t.bigint :installation_id, null: false
      t.string :repo_full_name, null: false
      t.text :access_token_ciphertext
      t.datetime :token_expires_at

      t.timestamps
    end

    add_index :github_installations, :installation_id, unique: true
    add_index :github_installations, :repo_full_name
  end
end
