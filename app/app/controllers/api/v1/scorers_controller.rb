module Api
  module V1
    class ScorersController < BaseController
      before_action :set_current_project
      before_action :set_scorer, only: [ :update, :destroy ]

      def index
        scorers = current_project.scorers.order(:name)
        render json: scorers.map { |s| Serializers::ScorerSerializer.call(s) }
      end

      def create
        scorer = Scorers::Create.call(
          project: current_project,
          name: params.require(:name),
          scorer_type: params.require(:scorer_type),
          content: params[:content],
          model_hint: params[:model_hint] || PromptVersion::DEFAULT_MODEL_HINT
        )
        render json: Serializers::ScorerSerializer.call(scorer), status: :created
      end

      def update
        @scorer.update!(scorer_update_params)
        render json: Serializers::ScorerSerializer.call(@scorer)
      end

      def destroy
        @scorer.update!(active: false)
        render json: Serializers::ScorerSerializer.call(@scorer)
      end

      private

      def set_scorer
        @scorer = current_project.scorers.find(params[:id])
      end

      def scorer_update_params
        params.permit(:name, :content, :model_hint, :active)
      end
    end
  end
end
