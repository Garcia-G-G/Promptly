class Workspace < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :projects, dependent: :destroy
  has_many :api_keys, dependent: :destroy

  normalizes :slug, with: -> { _1.strip.downcase }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
    format: { with: /\A[a-z0-9-]+\z/, message: "only allows lowercase letters, numbers, and hyphens" }
end
