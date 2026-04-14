class Experiment < ApplicationRecord
  ALLOWED_CANARY_STAGES = [ 1, 10, 50, 100 ].freeze

  belongs_to :prompt
  belongs_to :variant_a_version, class_name: "PromptVersion"
  belongs_to :variant_b_version, class_name: "PromptVersion"
  belongs_to :winner_version, class_name: "PromptVersion", optional: true

  enum :status, { draft: "draft", running: "running", paused: "paused", concluded: "concluded" }

  validates :name, presence: true, uniqueness: { scope: :prompt_id }
  validates :traffic_split, numericality: { only_integer: true, greater_than: 0, less_than: 100 }
  validates :environment, inclusion: { in: %w[dev staging production] }
  validate :variants_belong_to_same_prompt
  validate :variants_differ
  validate :canary_stage_allowed

  private

  def variants_belong_to_same_prompt
    return unless variant_a_version && variant_b_version

    unless variant_a_version.prompt_id == prompt_id && variant_b_version.prompt_id == prompt_id
      errors.add(:base, "Both variants must belong to the same prompt")
    end
  end

  def variants_differ
    return unless variant_a_version_id && variant_b_version_id

    if variant_a_version_id == variant_b_version_id
      errors.add(:base, "Variant A and Variant B must be different versions")
    end
  end

  def canary_stage_allowed
    return if canary_stage.nil?

    unless ALLOWED_CANARY_STAGES.include?(canary_stage)
      errors.add(:canary_stage, "must be one of: #{ALLOWED_CANARY_STAGES.join(', ')}")
    end
  end
end
