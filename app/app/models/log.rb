class Log < ApplicationRecord
  INPUT_VARS_MAX_BYTES = 100_000
  TOKENS_MAX_BYTES     = 5_000

  belongs_to :prompt
  belongs_to :prompt_version
  belongs_to :project
  belongs_to :experiment, optional: true
  belongs_to :scorer, optional: true

  has_one :experiment_result, dependent: :destroy

  validates :output, presence: true
  validates :score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true
  validate :input_vars_valid_format
  validate :tokens_valid_format

  private

  def input_vars_valid_format
    return if input_vars.blank?

    unless input_vars.is_a?(Hash)
      errors.add(:input_vars, "must be a JSON object")
      return
    end

    if input_vars.to_json.bytesize > INPUT_VARS_MAX_BYTES
      errors.add(:input_vars, "exceeds maximum size of #{INPUT_VARS_MAX_BYTES / 1000}KB")
    end
  end

  def tokens_valid_format
    return if tokens.blank?

    unless tokens.is_a?(Hash)
      errors.add(:tokens, "must be a JSON object")
      return
    end

    if tokens.to_json.bytesize > TOKENS_MAX_BYTES
      errors.add(:tokens, "exceeds maximum size of #{TOKENS_MAX_BYTES / 1000}KB")
    end
  end
end
