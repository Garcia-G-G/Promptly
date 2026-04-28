class AddCounterCaches < ActiveRecord::Migration[8.0]
  def change
    add_column :datasets, :dataset_rows_count, :integer, default: 0, null: false
    add_column :prompts,  :prompt_versions_count, :integer, default: 0, null: false
    add_column :projects, :prompts_count, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        safety_assured do
          execute <<~SQL
            UPDATE datasets
               SET dataset_rows_count = (
                 SELECT COUNT(*) FROM dataset_rows
                  WHERE dataset_rows.dataset_id = datasets.id
               )
          SQL

          execute <<~SQL
            UPDATE prompts
               SET prompt_versions_count = (
                 SELECT COUNT(*) FROM prompt_versions
                  WHERE prompt_versions.prompt_id = prompts.id
               )
          SQL

          execute <<~SQL
            UPDATE projects
               SET prompts_count = (
                 SELECT COUNT(*) FROM prompts
                  WHERE prompts.project_id = projects.id
               )
          SQL
        end
      end
    end
  end
end
