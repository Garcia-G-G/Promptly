module Experiments
  class Conclude
    def self.call(experiment:, winner:, reason: "bayesian_significance")
      winning_version = winner == :a ? experiment.variant_a_version : experiment.variant_b_version

      experiment.update!(
        status: :concluded,
        winner_version_id: winning_version.id,
        concluded_at: Time.current
      )

      experiment
    end
  end
end
