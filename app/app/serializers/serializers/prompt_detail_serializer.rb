module Serializers
  class PromptDetailSerializer
    def self.call(prompt)
      active_versions = prompt.prompt_versions.where.not(environment: :archived).order(:environment)
      {
        id: prompt.id,
        slug: prompt.slug,
        description: prompt.description,
        created_at: prompt.created_at.iso8601,
        active_versions: active_versions.map { |v| PromptVersionSerializer.call(v) }
      }
    end
  end
end
