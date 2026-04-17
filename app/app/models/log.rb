class Log < ApplicationRecord
  belongs_to :prompt
  belongs_to :prompt_version
  belongs_to :project
  belongs_to :experiment, optional: true
  belongs_to :scorer, optional: true

  has_one :experiment_result, dependent: :destroy

  validates :output, presence: true
end
