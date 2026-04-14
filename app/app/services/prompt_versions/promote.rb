module PromptVersions
  class Promote
    def self.call(prompt_version:, to_environment:)
      to_env = to_environment.to_s

      unless %w[staging production].include?(to_env)
        raise ArgumentError, "Cannot promote to #{to_env}"
      end

      prompt = prompt_version.prompt

      ActiveRecord::Base.transaction do
        # Archive current active version in target environment (if any)
        current = prompt.prompt_versions.where(environment: to_env).first
        current&.update!(environment: :archived)

        # Create new version in the target environment (immutable-append)
        prompt.prompt_versions.create!(
          content: prompt_version.content,
          variables: prompt_version.variables,
          model_hint: prompt_version.model_hint,
          environment: to_env,
          content_hash: prompt_version.content_hash,
          created_by: prompt_version.created_by,
          created_via: prompt_version.created_via,
          parent_version: prompt_version
        )
      end
    end
  end
end
