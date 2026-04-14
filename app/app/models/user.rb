class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  normalizes :email, with: -> { _1.strip.downcase }

  has_many :memberships, dependent: :destroy
  has_many :workspaces, through: :memberships
  has_many :owned_workspaces, class_name: "Workspace", foreign_key: :owner_id, dependent: :nullify
end
