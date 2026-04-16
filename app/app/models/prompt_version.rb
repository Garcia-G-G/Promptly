class PromptVersion < ApplicationRecord
  DEFAULT_MODEL_HINT = "claude-sonnet-4-6"

  belongs_to :prompt
  belongs_to :parent_version, class_name: "PromptVersion", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  enum :environment, { dev: "dev", staging: "staging", production: "production", archived: "archived" }
  has_many :security_scans, dependent: :destroy
  has_many :eval_runs, dependent: :destroy

  enum :created_via, { sdk: "sdk", ui: "ui", api: "api" }, prefix: :via

  validates :content, presence: true
  validates :version_number, presence: true, uniqueness: { scope: :prompt_id }
  validates :environment, inclusion: { in: environments.keys }
  validates :content, length: { maximum: 100_000 }

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
end
