class CheckCanaryRollbackJob < ApplicationJob
  queue_as :default

  def perform
    Experiment.where(status: :running).where.not(canary_stage: nil).find_each do |experiment|
      Experiments::AutoRollback.call(experiment: experiment)
    end
  end
end
