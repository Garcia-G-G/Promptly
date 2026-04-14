module Serializers
  class PromptSerializer
    def self.call(prompt)
      {
        id: prompt.id,
        slug: prompt.slug,
        description: prompt.description,
        created_at: prompt.created_at.iso8601
      }
    end
  end
end
