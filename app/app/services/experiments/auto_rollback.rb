module Experiments
  class AutoRollback
    CONSECUTIVE_THRESHOLD = 50

    def self.call(experiment:)
      new(experiment).call
    end

    def initialize(experiment)
      @experiment = experiment
    end

    def call
      return unless @experiment.running?
      return unless @experiment.canary_stage.present?
      return unless @experiment.auto_rollback_threshold.present?

      recent_scores = @experiment.experiment_results
        .where(variant: "b")
        .where.not(score: nil)
        .order(created_at: :desc)
        .limit(CONSECUTIVE_THRESHOLD)
        .pluck(:score)

      return if recent_scores.size < CONSECUTIVE_THRESHOLD

      avg = recent_scores.sum / recent_scores.size.to_f

      if avg < @experiment.auto_rollback_threshold
        @experiment.update!(status: :paused)
        Rails.logger.warn("[Experiment #{@experiment.id}] Auto-rollback: avg=#{avg.round(3)} < threshold=#{@experiment.auto_rollback_threshold}")
      end
    end
  end
end
