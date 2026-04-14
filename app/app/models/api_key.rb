class ApiKey < ApplicationRecord
  belongs_to :workspace

  validates :name, presence: true
  validates :key_prefix, presence: true
  validates :key_digest, presence: true, uniqueness: true

  attr_accessor :raw_key

  before_validation :generate_key, on: :create

  def self.authenticate(raw_key)
    return nil if raw_key.blank?

    digest = Digest::SHA256.hexdigest(raw_key)
    key = find_by(key_digest: digest, revoked_at: nil)
    key&.touch(:last_used_at)
    key
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  private

  def generate_key
    return if key_digest.present?

    raw = "pk_#{SecureRandom.hex(24)}"
    self.raw_key = raw
    self.key_prefix = raw[0, 8]
    self.key_digest = Digest::SHA256.hexdigest(raw)
  end
end
