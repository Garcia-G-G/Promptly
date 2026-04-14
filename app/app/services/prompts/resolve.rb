module Prompts
  class Resolve
    DEFAULT_ENVIRONMENT = "production"

    def self.call(project:, slug:, environment: DEFAULT_ENVIRONMENT, request_id: nil)
      prompt = project.prompts.find_by(slug: slug)
      raise Prompts::NotFound, "Prompt '#{slug}' not found" unless prompt

      baseline = prompt.prompt_versions.find_by(environment: environment)
      raise Prompts::NoActiveVersion, "No active version for '#{slug}' in '#{environment}'" unless baseline

      experiment = prompt.experiments.find_by(status: :running, environment: environment)

      result = if experiment.nil? || request_id.blank?
        { prompt: prompt, version: baseline, experiment: nil, variant: nil, source: :baseline }
      else
        route_through_experiment(experiment, baseline, prompt, request_id)
      end

      instrument(result, slug, environment)
      result
    end

    def self.route_through_experiment(experiment, baseline, prompt, request_id)
      assignment = AbRouter::Assign.call(experiment: experiment, request_id: request_id)

      case assignment
      when :not_in_canary
        { prompt: prompt, version: baseline, experiment: experiment, variant: nil, source: :not_in_canary }
      when :a
        { prompt: prompt, version: experiment.variant_a_version, experiment: experiment, variant: :a, source: :experiment }
      when :b
        { prompt: prompt, version: experiment.variant_b_version, experiment: experiment, variant: :b, source: :experiment }
      end
    end

    def self.instrument(result, slug, environment)
      ActiveSupport::Notifications.instrument("resolve.promptly", {
        prompt_slug: slug,
        environment: environment,
        source: result[:source],
        variant: result[:variant],
        experiment_id: result[:experiment]&.id
      })
    end

    private_class_method :route_through_experiment, :instrument
  end
end
