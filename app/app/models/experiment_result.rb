class ExperimentResult < ApplicationRecord
  belongs_to :experiment
  belongs_to :log

  validates :variant, presence: true, inclusion: { in: %w[a b] }
end
