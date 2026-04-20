class GithubInstallation < ApplicationRecord
  belongs_to :workspace

  encrypts :access_token_ciphertext

  validates :installation_id, presence: true, uniqueness: true
  validates :repo_full_name, presence: true

  def token_expired?
    token_expires_at.nil? || token_expires_at < 5.minutes.from_now
  end
end
