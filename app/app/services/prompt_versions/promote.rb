module PromptVersions
  class Promote
    def self.call(prompt_version:, to_environment:, force: false)
      to_env = to_environment.to_s

      unless %w[staging production].include?(to_env)
        raise ArgumentError, "Cannot promote to #{to_env}"
      end

      # Security gate for production
      if to_env == "production" && !force
        check = SecurityScans::Check.call(prompt_version: prompt_version)
        unless check[:allowed]
          raise PromptVersions::SecurityBlocked,
            "Promotion blocked: security scan flagged issues. Override with force: true."
        end
      end

      prompt = prompt_version.prompt

      new_version = ActiveRecord::Base.transaction do
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

      # Bust the resolve cache so the next call sees the new version.
      Prompts::Resolve.bust_cache(project_id: prompt.project_id, slug: prompt.slug, environment: to_env)

      new_version
    end
  end
end
