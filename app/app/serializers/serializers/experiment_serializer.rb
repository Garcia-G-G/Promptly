module Serializers
  class ExperimentSerializer
    def self.call(experiment)
      {
        id: experiment.id,
        name: experiment.name,
        status: experiment.status,
        prompt_id: experiment.prompt_id,
        variant_a_version_id: experiment.variant_a_version_id,
        variant_b_version_id: experiment.variant_b_version_id,
        traffic_split: experiment.traffic_split,
        environment: experiment.environment,
        canary_stage: experiment.canary_stage,
        auto_rollback_threshold: experiment.auto_rollback_threshold,
        winner_version_id: experiment.winner_version_id,
        started_at: experiment.started_at&.iso8601,
        concluded_at: experiment.concluded_at&.iso8601,
        created_at: experiment.created_at.iso8601
      }
    end
  end
end
