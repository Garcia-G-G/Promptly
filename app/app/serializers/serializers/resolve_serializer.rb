module Serializers
  class ResolveSerializer
    def self.call(version)
      {
        content: version.content,
        version_number: version.version_number,
        model_hint: version.model_hint,
        content_hash: version.content_hash,
        variables_schema: version.variables
      }
    end
  end
end
