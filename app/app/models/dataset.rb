class Dataset < ApplicationRecord
  belongs_to :project
  has_many :dataset_rows, dependent: :destroy
  has_many :eval_runs, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :project_id }
end
