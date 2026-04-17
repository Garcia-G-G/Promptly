module Serializers
  class PromptVersionSerializer
    def self.call(version)
      {
        id: version.id,
        version_number: version.version_number,
        content: version.content,
        variables: version.variables,
        model_hint: version.model_hint,
        environment: version.environment,
        content_hash: version.content_hash,
        created_at: version.created_at.iso8601
      }
    end
  end
end
