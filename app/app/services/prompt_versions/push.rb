module PromptVersions
  class Push
    def self.call(prompt:, content:, variables: [], model_hint: PromptVersion::DEFAULT_MODEL_HINT, created_by: nil, created_via: :api, parent_version: nil)
      version = prompt.prompt_versions.create!(
        content: content,
        variables: variables,
        model_hint: model_hint,
        environment: :dev,
        created_by: created_by,
        created_via: created_via,
        parent_version: parent_version
      )

      SecurityScans::Run.call(prompt_version: version)

      version
    end
  end
end
