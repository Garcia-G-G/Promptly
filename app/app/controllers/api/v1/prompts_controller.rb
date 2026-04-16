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
        env = params[:environment] || Prompts::Resolve::DEFAULT_ENVIRONMENT
        result = Prompts::Resolve.call(
          project: current_project,
          slug: params[:slug],
          environment: env,
          request_id: params[:request_id]
        )

        version = result[:version]
        response.headers["X-Promptly-Version"] = version.version_number.to_s
        response.headers["X-Promptly-Content-Hash"] = version.content_hash
        response.headers["X-Promptly-Source"] = result[:source].to_s

        if result[:experiment]
          response.headers["X-Promptly-Experiment-Id"] = result[:experiment].id.to_s
          response.headers["X-Promptly-Variant"] = (result[:variant] || "baseline").to_s
        end

        render json: Serializers::ResolveSerializer.call(version)
      end

      def promote
        version = @prompt.prompt_versions.find(params.require(:version_id))
        new_version = PromptVersions::Promote.call(
          prompt_version: version,
          to_environment: params.require(:to_environment),
          force: params[:force] == true || params[:force] == "true"
        )
        render json: Serializers::PromptVersionSerializer.call(new_version), status: :created
      end

      def log
        log_record = Logs::Create.call(
          prompt: @prompt,
          project: current_project,
          params: log_params
        )
        render json: { accepted: true, log_id: log_record.id }, status: :accepted
      end

      private

      def log_params
        {
          request_id: params[:request_id],
          output: params.require(:output),
          input_vars: params[:input_vars],
          latency_ms: params[:latency_ms],
          tokens: params[:tokens],
          model_version: params[:model_version],
          environment: params[:environment],
          otel_trace_id: params[:otel_trace_id],
          otel_span_id: params[:otel_span_id]
        }
      end

      def set_prompt
        @prompt = current_project.prompts.find_by!(slug: params[:slug])
      end
    end
  end
end
