module Web
  class ExperimentsController < Web::BaseController
    before_action :set_experiment,
      only: [ :show, :start, :pause, :resume, :conclude, :advance_canary ]

    def index
      base = Experiment.joins(prompt: { project: :workspace })
        .where(workspaces: { id: @workspace.id })

      @status_filter = params[:status].presence
      scope = base.includes(prompt: :project, variant_a_version: [], variant_b_version: [])
        .order(created_at: :desc)
      scope = scope.where(status: @status_filter) if @status_filter

      @experiments = scope
      @counts = {
        all:       base.count,
        running:   base.where(status: :running).count,
        draft:     base.where(status: :draft).count,
        concluded: base.where(status: :concluded).count
      }
    end

    def show
      @stats = Experiments::Stats.call(experiment: @experiment)
      @significance = Experiments::BayesianSignificance.call(experiment: @experiment)

      # One grouped aggregate query instead of four per-variant selects.
      stats = @experiment.experiment_results
        .group(:variant)
        .pluck(Arel.sql("variant, COUNT(*), AVG(score)"))
        .to_h { |variant, total, avg| [ variant, { count: total.to_i, avg: avg&.to_f&.round(3) } ] }

      @variant_a_count = stats.dig("a", :count) || 0
      @variant_b_count = stats.dig("b", :count) || 0
      @variant_a_avg   = stats.dig("a", :avg)
      @variant_b_avg   = stats.dig("b", :avg)

      @recent_results = @experiment.experiment_results
        .includes(:log)
        .order(created_at: :desc)
        .limit(50)
    end

    def new
      @prompts = workspace_prompts_for_form
      @experiment = Experiment.new(traffic_split: 50, environment: "production")
    end

    def create
      prompt = workspace_prompts.find(experiment_params[:prompt_id])
      experiment = Experiments::Create.call(
        prompt: prompt,
        name: experiment_params[:name],
        variant_a_version_id: experiment_params[:variant_a_version_id],
        variant_b_version_id: experiment_params[:variant_b_version_id],
        traffic_split: experiment_params[:traffic_split].to_i,
        environment: experiment_params[:environment],
        canary_stage: experiment_params[:canary_stage].presence&.to_i,
        auto_rollback_threshold: experiment_params[:auto_rollback_threshold].presence&.to_f
      )
      redirect_to workspace_web_experiment_path(@workspace.slug, experiment),
        notice: "Experiment '#{experiment.name}' created."
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound, ArgumentError => e
      @prompts = workspace_prompts_for_form
      @experiment = Experiment.new(experiment_params.to_h.symbolize_keys)
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_entity
    end

    def start
      Experiments::UpdateStatus.call(experiment: @experiment, status: :running)
      redirect_with_experiment_notice("Experiment started.")
    rescue ArgumentError => e
      redirect_with_experiment_alert(e.message)
    end

    def pause
      Experiments::UpdateStatus.call(experiment: @experiment, status: :paused)
      redirect_with_experiment_notice("Experiment paused.")
    rescue ArgumentError => e
      redirect_with_experiment_alert(e.message)
    end

    def resume
      Experiments::UpdateStatus.call(experiment: @experiment, status: :running)
      redirect_with_experiment_notice("Experiment resumed.")
    rescue ArgumentError => e
      redirect_with_experiment_alert(e.message)
    end

    def conclude
      Experiments::UpdateStatus.call(
        experiment: @experiment,
        status: :concluded,
        winner_version_id: params[:winner_version_id]
      )
      redirect_with_experiment_notice("Experiment concluded.")
    rescue ArgumentError => e
      redirect_with_experiment_alert(e.message)
    end

    def advance_canary
      stage = params[:stage].to_i
      Experiments::AdvanceCanary.call(experiment: @experiment, to: stage)
      redirect_with_experiment_notice("Canary advanced to #{stage}%.")
    rescue ArgumentError => e
      redirect_with_experiment_alert(e.message)
    end

    private

    def set_experiment
      @experiment = Experiment.joins(prompt: { project: :workspace })
        .where(workspaces: { id: @workspace.id })
        .includes(:prompt, :variant_a_version, :variant_b_version, :winner_version)
        .find(params[:id])
    end

    def workspace_prompts
      Prompt.joins(:project).where(projects: { workspace_id: @workspace.id })
    end

    def workspace_prompts_for_form
      workspace_prompts.includes(:prompt_versions, :project).order(:slug)
    end

    def experiment_params
      params.require(:experiment).permit(
        :prompt_id, :name, :variant_a_version_id, :variant_b_version_id,
        :traffic_split, :environment, :canary_stage, :auto_rollback_threshold
      )
    end

    def redirect_with_experiment_notice(message)
      redirect_to workspace_web_experiment_path(@workspace.slug, @experiment), notice: message
    end

    def redirect_with_experiment_alert(message)
      redirect_to workspace_web_experiment_path(@workspace.slug, @experiment), alert: message
    end
  end
end
