class EvalRunResult < ApplicationRecord
  belongs_to :eval_run
  belongs_to :dataset_row
end
