module Prompts
  class Resolve
    DEFAULT_ENVIRONMENT = "production"

    def self.call(project:, slug:, environment: DEFAULT_ENVIRONMENT)
      prompt = project.prompts.find_by(slug: slug)
      raise Prompts::NotFound, "Prompt '#{slug}' not found" unless prompt

      version = prompt.prompt_versions.find_by(environment: environment)
      raise Prompts::NoActiveVersion, "No active version for '#{slug}' in '#{environment}'" unless version

      { prompt: prompt, version: version }
    end
  end
end
