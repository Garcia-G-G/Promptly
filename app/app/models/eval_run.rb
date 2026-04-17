class EvalRun < ApplicationRecord
  belongs_to :prompt_version
  belongs_to :dataset
  belongs_to :scorer

  has_many :eval_run_results, dependent: :destroy

  enum :status, { queued: "queued", running: "running", done: "done", failed: "failed" }
end
