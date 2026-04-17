module Api
  module V1
    class PromptVersionsController < BaseController
      before_action :set_current_project

      def create
        prompt = current_project.prompts.find_by!(slug: params[:prompt_slug])
        version = PromptVersions::Push.call(
          prompt: prompt,
          content: params.require(:content),
          variables: params[:variables] || [],
          model_hint: params[:model_hint] || PromptVersion::DEFAULT_MODEL_HINT,
          created_via: :api
        )
        render json: Serializers::PromptVersionSerializer.call(version), status: :created
      end
    end
  end
end
