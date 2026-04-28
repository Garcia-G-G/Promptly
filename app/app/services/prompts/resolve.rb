module Prompts
  class Resolve
    DEFAULT_ENVIRONMENT = "production"
    RESOLVE_CACHE_TTL = 5.minutes
    EXPERIMENT_FLAG_TTL = 1.minute

    def self.call(project:, slug:, environment: DEFAULT_ENVIRONMENT, request_id: nil)
      # Fast path: when no experiment is running for this prompt+env and
      # the caller isn't requesting per-request routing, serve a cached
      # baseline result. The has-experiment lookup is itself cached for
      # a minute so the hot path is one Redis read.
      if !experiment_running?(project, slug, environment)
        cached = Rails.cache.read(cache_key(project, slug, environment))
        if cached
          result = cached.merge(source: :cache)
          instrument(result, slug, environment)
          return result
        end
      end

      result = resolve_uncached(project: project, slug: slug, environment: environment, request_id: request_id)

      # Only cache baselines — experiment routing is per-request.
      if result[:experiment].nil?
        Rails.cache.write(cache_key(project, slug, environment), result.except(:source), expires_in: RESOLVE_CACHE_TTL)
      end

      instrument(result, slug, environment)
      result
    end

    def self.cache_key(project, slug, environment)
      "resolve:#{project.id}:#{slug}:#{environment}"
    end

    def self.bust_cache(project_id:, slug:, environment:)
      Rails.cache.delete("resolve:#{project_id}:#{slug}:#{environment}")
      Rails.cache.delete("has_experiment:#{project_id}:#{slug}:#{environment}")
    end

    def self.experiment_running?(project, slug, environment)
      Rails.cache.fetch("has_experiment:#{project.id}:#{slug}:#{environment}", expires_in: EXPERIMENT_FLAG_TTL) do
        Experiment.joins(:prompt)
          .where(prompts: { project_id: project.id, slug: slug })
          .where(environment: environment, status: :running)
          .exists?
      end
    end

    def self.resolve_uncached(project:, slug:, environment:, request_id:)
      prompt = project.prompts.find_by(slug: slug)
      raise Prompts::NotFound, "Prompt '#{slug}' not found" unless prompt

      baseline = prompt.prompt_versions.find_by(environment: environment)
      raise Prompts::NoActiveVersion, "No active version for '#{slug}' in '#{environment}'" unless baseline

      experiment = prompt.experiments.find_by(status: :running, environment: environment)

      if experiment.nil? || request_id.blank?
        { prompt: prompt, version: baseline, experiment: nil, variant: nil, source: :baseline }
      else
        route_through_experiment(experiment, baseline, prompt, request_id)
      end
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

    private_class_method :cache_key, :experiment_running?, :resolve_uncached,
                         :route_through_experiment, :instrument
  end
end
