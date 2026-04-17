class EvaluateExperimentsJob < ApplicationJob
  queue_as :default

  def perform
    Experiment.where(status: :running).find_each do |experiment|
      result = Experiments::BayesianSignificance.call(experiment: experiment)
      next unless result

      experiment.update_column(:significance, result[:significance])

      if result[:winner]
        Experiments::Conclude.call(experiment: experiment, winner: result[:winner])
        Rails.logger.info("[Experiment #{experiment.id}] Concluded: winner=#{result[:winner]}")
      end
    end
  end
end
