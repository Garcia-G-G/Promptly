class EvalRun < ApplicationRecord
  belongs_to :prompt_version
  belongs_to :dataset
  belongs_to :scorer

  has_many :eval_run_results, dependent: :destroy

  enum :status, { queued: "queued", running: "running", done: "done", failed: "failed" }

  validates :pass_threshold,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
    allow_nil: true
  validates :aggregate_score,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
    allow_nil: true
  validates :pass_rate,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
    allow_nil: true
end
