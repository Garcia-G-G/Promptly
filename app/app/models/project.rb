class Project < ApplicationRecord
  belongs_to :workspace

  has_many :prompts, dependent: :destroy

  normalizes :slug, with: -> { _1.strip.downcase }

  validates :name, presence: true
  validates :slug, presence: true,
    uniqueness: { scope: :workspace_id },
    format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }
end
