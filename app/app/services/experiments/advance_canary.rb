module Experiments
  class AdvanceCanary
    STAGES = [ 1, 10, 50, 100 ].freeze

    def self.call(experiment:, to:)
      to_stage = to.to_i

      raise ArgumentError, "Experiment must be running" unless experiment.running?
      raise ArgumentError, "Invalid canary stage: #{to_stage}. Must be one of: #{STAGES.join(', ')}" unless STAGES.include?(to_stage)

      current = experiment.canary_stage || 0
      raise ArgumentError, "Cannot go backwards: current stage is #{current}, requested #{to_stage}" if to_stage <= current

      experiment.update!(canary_stage: to_stage)
      experiment
    end
  end
end
