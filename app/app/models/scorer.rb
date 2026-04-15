class Scorer < ApplicationRecord
  belongs_to :project

  enum :scorer_type, { llm_judge: "llm_judge", exact_match: "exact_match", regex: "regex", custom: "custom" }, prefix: :type

  validates :name, presence: true, uniqueness: { scope: :project_id }
  validates :scorer_type, inclusion: { in: scorer_types.keys }

  scope :active, -> { where(active: true) }
end
