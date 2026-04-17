module Experiments
  class Create
    def self.call(prompt:, name:, variant_a_version_id:, variant_b_version_id:, traffic_split: 50, environment: "production", canary_stage: nil, auto_rollback_threshold: nil)
      experiment = prompt.experiments.create!(
        name: name,
        variant_a_version_id: variant_a_version_id,
        variant_b_version_id: variant_b_version_id,
        traffic_split: traffic_split,
        environment: environment,
        canary_stage: canary_stage,
        auto_rollback_threshold: auto_rollback_threshold,
        status: :draft
      )
      experiment
    end
  end
end
