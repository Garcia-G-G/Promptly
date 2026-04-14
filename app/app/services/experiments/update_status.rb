module Experiments
  class UpdateStatus
    def self.call(experiment:, status:, winner_version_id: nil)
      new_status = status.to_s

      case new_status
      when "running"
        raise ArgumentError, "Cannot start a concluded experiment" if experiment.concluded?
        experiment.update!(status: :running, started_at: experiment.started_at || Time.current)
      when "paused"
        raise ArgumentError, "Can only pause a running experiment" unless experiment.running?
        experiment.update!(status: :paused)
      when "concluded"
        raise ArgumentError, "Can only conclude a running or paused experiment" unless experiment.running? || experiment.paused?
        attrs = { status: :concluded, concluded_at: Time.current }
        attrs[:winner_version_id] = winner_version_id if winner_version_id.present?
        experiment.update!(attrs)
      else
        raise ArgumentError, "Invalid status: #{new_status}"
      end

      experiment
    end
  end
end
