class DatasetRow < ApplicationRecord
  INPUT_VARS_MAX_BYTES = 100_000
  TAGS_MAX_BYTES = 10_000

  belongs_to :dataset, counter_cache: true

  validates :input_vars, presence: true
  validate :input_vars_valid_format
  validate :tags_valid_format
  validate :payload_size_limit

  private

  def input_vars_valid_format
    return if input_vars.blank?

    unless input_vars.is_a?(Hash)
      errors.add(:input_vars, "must be a JSON object")
      return
    end

    input_vars.each_key do |key|
      unless key.is_a?(String)
        errors.add(:input_vars, "keys must be strings")
        return
      end
    end
  end

  def tags_valid_format
    return if tags.blank?

    unless tags.is_a?(Array) && tags.all? { |t| t.is_a?(String) }
      errors.add(:tags, "must be an array of strings")
    end
  end

  def payload_size_limit
    if input_vars.present? && input_vars.to_json.bytesize > INPUT_VARS_MAX_BYTES
      errors.add(:input_vars, "exceeds maximum size of #{INPUT_VARS_MAX_BYTES / 1000}KB")
    end
    if tags.present? && tags.to_json.bytesize > TAGS_MAX_BYTES
      errors.add(:tags, "exceeds maximum size of #{TAGS_MAX_BYTES / 1000}KB")
    end
  end
end
