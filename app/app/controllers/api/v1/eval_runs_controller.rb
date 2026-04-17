module Api
  module V1
    class EvalRunsController < BaseController
      before_action :set_current_project

      def index
        scope = EvalRun.joins(prompt_version: { prompt: :project })
          .where(projects: { id: current_project.id })

        if params[:prompt_version_id].present?
          scope = scope.where(prompt_version_id: params[:prompt_version_id])
        end

        runs = scope.order(created_at: :desc).limit(50)
        render json: runs.map { |r| Serializers::EvalRunSerializer.call(r) }
      end

      def show
        eval_run = EvalRun.joins(prompt_version: { prompt: :project })
          .where(projects: { id: current_project.id })
          .find(params[:id])
        render json: Serializers::EvalRunSerializer.call(eval_run, include_results: true)
      end

      def create
        prompt_version = PromptVersion.joins(prompt: :project)
          .where(projects: { id: current_project.id })
          .find(params.require(:prompt_version_id))
        dataset = current_project.datasets.find(params.require(:dataset_id))
        scorer = current_project.scorers.find(params.require(:scorer_id))

        eval_run = EvalRuns::Create.call(
          prompt_version: prompt_version,
          dataset: dataset,
          scorer: scorer,
          pass_threshold: params[:pass_threshold] || 0.6
        )
        render json: Serializers::EvalRunSerializer.call(eval_run), status: :created
      end
    end
  end
end
