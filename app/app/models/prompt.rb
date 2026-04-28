class Prompt < ApplicationRecord
  belongs_to :project, counter_cache: true

  has_many :prompt_versions, dependent: :destroy
  has_many :experiments, dependent: :destroy
  has_many :logs, dependent: :destroy
  belongs_to :default_scorer, class_name: "Scorer", optional: true

  normalizes :slug, with: -> { _1.strip.downcase }

  validates :slug, presence: true,
    uniqueness: { scope: :project_id },
    format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }
  validates :description, length: { maximum: 2000 }, allow_blank: true
end
