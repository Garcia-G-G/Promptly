class Scorer < ApplicationRecord
  belongs_to :project

  enum :scorer_type, { llm_judge: "llm_judge", exact_match: "exact_match", regex: "regex", custom: "custom" }, prefix: :type

  validates :name, presence: true, uniqueness: { scope: :project_id }
  validates :scorer_type, inclusion: { in: scorer_types.keys }
  validate :regex_content_valid

  scope :active, -> { where(active: true) }

  private

  def regex_content_valid
    return unless type_regex? && content.present?

    if content.length > 500
      errors.add(:content, "regex pattern too long (max 500 characters)")
      return
    end

    Regexp.new(content)
  rescue RegexpError => e
    errors.add(:content, "invalid regex: #{e.message}")
  end
end
