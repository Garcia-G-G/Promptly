# frozen_string_literal: true

module Scorers
  class Create
    def self.call(project:, name:, scorer_type:, content: nil, model_hint: PromptVersion::DEFAULT_MODEL_HINT)
      project.scorers.create!(
        name: name,
        scorer_type: scorer_type,
        content: content,
        model_hint: model_hint
      )
    end
  end
end
