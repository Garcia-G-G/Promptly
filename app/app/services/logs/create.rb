# frozen_string_literal: true

module Logs
  class Create
    def self.call(prompt:, project:, params:)
      # 1. Resolve the prompt version for the environment
      environment = params[:environment] || Prompts::Resolve::DEFAULT_ENVIRONMENT
      version = prompt.prompt_versions.find_by(environment: environment)
      version ||= prompt.prompt_versions.order(version_number: :desc).first

      # 2. Check for experiment assignment via request_id
      experiment_id = nil
      variant = nil

      if params[:request_id].present?
        experiment = prompt.experiments.find_by(status: :running, environment: environment)
        if experiment
          begin
            Promptly::Redis.with do |redis|
              sticky_key = Promptly::Redis.key("exp", experiment.id, "req", params[:request_id])
              stored_variant = redis.get(sticky_key)
              if stored_variant
                experiment_id = experiment.id
                variant = stored_variant
              end
            end
          rescue => e
            Rails.logger.warn("Logs::Create Redis lookup failed: #{e.message}")
          end
        end
      end

      # 3. Create the Log + ExperimentResult in a transaction
      log = nil
      ActiveRecord::Base.transaction do
        log = Log.create!(
          prompt: prompt,
          prompt_version: version,
          project: project,
          request_id: params[:request_id],
          input_vars: params[:input_vars] || {},
          output: params[:output],
          latency_ms: params[:latency_ms],
          tokens: params[:tokens] || {},
          model_version: params[:model_version],
          experiment_id: experiment_id,
          variant: variant,
          otel_trace_id: params[:otel_trace_id],
          otel_span_id: params[:otel_span_id]
        )

        if experiment_id.present? && variant.present?
          ExperimentResult.create!(
            experiment_id: experiment_id,
            log: log,
            variant: variant
          )
        end
      end

      # 4. Resolve scorer: prompt default > project active scorer > nil
      scorer = prompt.default_scorer
      scorer ||= project.scorers.active.find_by(scorer_type: :llm_judge)

      # 5. Enqueue scoring job if scorer available
      if scorer
        ScoreOutputJob.perform_later(log_id: log.id, scorer_id: scorer.id)
      end

      log
    end
  end
end
