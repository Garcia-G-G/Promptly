class DatasetRow < ApplicationRecord
  belongs_to :dataset
  validates :input_vars, presence: true
end
