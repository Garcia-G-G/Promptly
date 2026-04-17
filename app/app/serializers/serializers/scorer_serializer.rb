module Serializers
  class ScorerSerializer
    def self.call(scorer)
      {
        id: scorer.id,
        name: scorer.name,
        scorer_type: scorer.scorer_type,
        content: scorer.content,
        model_hint: scorer.model_hint,
        version_number: scorer.version_number,
        active: scorer.active,
        created_at: scorer.created_at.iso8601
      }
    end
  end
end
