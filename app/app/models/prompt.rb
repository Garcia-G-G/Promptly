class Prompt < ApplicationRecord
  belongs_to :project

  has_many :prompt_versions, dependent: :destroy

  normalizes :slug, with: -> { _1.strip.downcase }

  validates :slug, presence: true,
    uniqueness: { scope: :project_id },
    format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }
end
