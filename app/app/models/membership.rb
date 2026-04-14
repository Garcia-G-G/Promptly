class Membership < ApplicationRecord
  belongs_to :workspace
  belongs_to :user

  enum :role, { owner: "owner", admin: "admin", developer: "developer", viewer: "viewer" }

  validates :role, inclusion: { in: roles.keys }
  validates :user_id, uniqueness: { scope: :workspace_id }
end
