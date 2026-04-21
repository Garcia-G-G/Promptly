module PromptVersions
  class Push
    def self.call(prompt:, content:, variables: [], model_hint: PromptVersion::DEFAULT_MODEL_HINT, created_by: nil, created_via: :api, parent_version: nil)
      version = ActiveRecord::Base.transaction do
        # Only one active version per environment is allowed (unique index
        # idx_prompt_versions_one_active_per_env). Archive any existing
        # dev version before appending the new one.
        prompt.prompt_versions.where(environment: :dev).update_all(environment: :archived)

        prompt.prompt_versions.create!(
          content: content,
          variables: variables,
          model_hint: model_hint,
          environment: :dev,
          created_by: created_by,
          created_via: created_via,
          parent_version: parent_version
        )
      end

      SecurityScans::Run.call(prompt_version: version)

      version
    end
  end
end
