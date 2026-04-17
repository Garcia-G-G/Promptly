class AddSignificanceToExperiments < ActiveRecord::Migration[8.1]
  def change
    add_column :experiments, :significance, :float
  end
end
