module Experiments
  class Stats
    def self.call(experiment:)
      counts = AbRouter::Counts.call(experiment: experiment)

      {
        experiment_id: experiment.id,
        name: experiment.name,
        status: experiment.status,
        variant_a: {
          version_id: experiment.variant_a_version_id,
          count: counts[:a]
        },
        variant_b: {
          version_id: experiment.variant_b_version_id,
          count: counts[:b]
        },
        not_in_canary: counts[:not_in_canary],
        traffic_split: experiment.traffic_split,
        canary_stage: experiment.canary_stage,
        started_at: experiment.started_at&.iso8601,
        concluded_at: experiment.concluded_at&.iso8601
      }
    end
  end
end
