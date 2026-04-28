class ApiKey < ApplicationRecord
  belongs_to :workspace

  validates :name, presence: true, length: { maximum: 255 }
  validates :key_prefix, presence: true
  validates :key_digest, presence: true, uniqueness: true

  attr_accessor :raw_key

  before_validation :generate_key, on: :create

  # Authenticate a raw API key. Uses the prefix for an index lookup
  # (narrow candidate set) and then a constant-time digest comparison
  # so authentication latency doesn't leak information about the key.
  def self.authenticate(raw_key)
    return nil if raw_key.blank?
    return nil unless raw_key.length >= 8

    prefix = raw_key[0, 8]
    digest = Digest::SHA256.hexdigest(raw_key)
    candidates = where(key_prefix: prefix, revoked_at: nil).limit(5)

    key = candidates.find do |candidate|
      ActiveSupport::SecurityUtils.secure_compare(candidate.key_digest, digest)
    end

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
