module Api
  module V1
    class PromptsController < BaseController
      before_action :set_current_project
      before_action :set_prompt, only: [ :show, :resolve, :promote, :log ]

      def index
        prompts = current_project.prompts.order(:slug)
        render json: prompts.map { |p| Serializers::PromptSerializer.call(p) }
      end

      def create
        prompt = Prompts::Create.call(
          project: current_project,
          slug: params.require(:slug),
          description: params[:description]
        )
        render json: Serializers::PromptSerializer.call(prompt), status: :created
      end

      def show
        render json: Serializers::PromptDetailSerializer.call(@prompt)
      end

      def resolve
        env = params[:environment] || "production"
        result = Prompts::Resolve.call(
          project: current_project,
          slug: params[:slug],
          environment: env
        )

        version = result[:version]
        response.headers["X-Promptly-Version"] = version.version_number.to_s
        response.headers["X-Promptly-Content-Hash"] = version.content_hash

        render json: Serializers::ResolveSerializer.call(version)
      end

      def promote
        version = @prompt.prompt_versions.find(params.require(:version_id))
        new_version = PromptVersions::Promote.call(
          prompt_version: version,
          to_environment: params.require(:to_environment)
        )
        render json: Serializers::PromptVersionSerializer.call(new_version), status: :created
      end

      def log
        render json: { accepted: true }, status: :accepted
      end

      private

      def set_prompt
        @prompt = current_project.prompts.find_by!(slug: params[:slug])
      end
    end
  end
end
