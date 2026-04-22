module Api
  module V1
    class ExperimentsController < BaseController
      before_action :set_current_project, only: [ :index, :create ]
      before_action :set_experiment, only: [ :update, :advance_canary, :stats ]

      def index
        prompt = current_project.prompts.find_by!(slug: params[:prompt_slug])
        experiments = prompt.experiments.order(created_at: :desc)
        render json: experiments.map { |e| Serializers::ExperimentSerializer.call(e) }
      end

      def create
        prompt = current_project.prompts.find_by!(slug: params[:prompt_slug])
        experiment = Experiments::Create.call(
          prompt: prompt,
          name: params.require(:name),
          variant_a_version_id: params.require(:variant_a_version_id),
          variant_b_version_id: params.require(:variant_b_version_id),
          traffic_split: params[:traffic_split] || 50,
          environment: params[:environment] || "production",
          canary_stage: params[:canary_stage],
          auto_rollback_threshold: params[:auto_rollback_threshold]
        )
        render json: Serializers::ExperimentSerializer.call(experiment), status: :created
      end

      def update
        Experiments::UpdateStatus.call(
          experiment: @experiment,
          status: params.require(:status),
          winner_version_id: params[:winner_version_id]
        )
        render json: Serializers::ExperimentSerializer.call(@experiment.reload)
      end

      def advance_canary
        Experiments::AdvanceCanary.call(
          experiment: @experiment,
          to: params.require(:to)
        )
        render json: Serializers::ExperimentSerializer.call(@experiment.reload)
      end

      def stats
        result = Experiments::Stats.call(experiment: @experiment)
        render json: result
      end

      private

      def set_experiment
        @experiment = Experiment.joins(prompt: { project: :workspace })
          .where(workspaces: { id: current_workspace.id })
          .find(params[:id])
      end
    end
  end
end
