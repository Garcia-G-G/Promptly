class PromptVersion < ApplicationRecord
  DEFAULT_MODEL_HINT = "gpt-4o"

  belongs_to :prompt
  belongs_to :parent_version, class_name: "PromptVersion", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  enum :environment, { dev: "dev", staging: "staging", production: "production", archived: "archived" }
  has_many :security_scans, dependent: :destroy
  has_many :eval_runs, dependent: :destroy

  enum :created_via, { sdk: "sdk", ui: "ui", api: "api" }, prefix: :via

  CONTENT_MAX_BYTES = 100_000

  validates :content, presence: true
  validates :version_number, presence: true, uniqueness: { scope: :prompt_id }
  validates :environment, inclusion: { in: environments.keys }
  validate :content_size_limit
  validate :variables_valid_schema

  before_validation :compute_content_hash
  before_validation :assign_version_number, on: :create

  private

  def compute_content_hash
    self.content_hash = Digest::SHA256.hexdigest(content.to_s) if content.present?
  end

  def assign_version_number
    return if version_number.present?

    max = prompt&.prompt_versions&.maximum(:version_number) || 0
    self.version_number = max + 1
  end

  def content_size_limit
    return if content.blank?

    if content.bytesize > CONTENT_MAX_BYTES
      errors.add(:content, "exceeds maximum size of #{CONTENT_MAX_BYTES / 1000}KB")
    end
  end

  def variables_valid_schema
    return if variables.blank?

    unless variables.is_a?(Array)
      errors.add(:variables, "must be an array")
      return
    end

    variables.each_with_index do |var, i|
      unless var.is_a?(Hash) && var["name"].is_a?(String) && !var["name"].empty?
        errors.add(:variables, "item at index #{i} must have a 'name' string field")
        break
      end
    end
  end
end
