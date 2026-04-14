module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_key!

      rescue_from ActiveRecord::RecordNotFound do
        render_error("not_found", status: :not_found)
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render_error("validation_failed", message: e.record.errors.full_messages.join(", "),
          details: e.record.errors.as_json, status: :unprocessable_entity)
      end

      rescue_from ActionController::ParameterMissing do |e|
        render_error("missing_parameter", message: "Missing required parameter: #{e.param}", status: :bad_request)
      end

      rescue_from Prompts::NotFound do |e|
        render_error("not_found", message: e.message, status: :not_found)
      end

      rescue_from Prompts::NoActiveVersion do |e|
        render_error("no_active_version", message: e.message, status: :not_found)
      end

      rescue_from ArgumentError do |e|
        render_error("invalid_argument", message: e.message, status: :unprocessable_entity)
      end

      private

      def render_error(code, message: nil, status: :internal_server_error, **extra)
        body = { error: code }
        body[:message] = message if message
        body.merge!(extra.except(:status))
        render json: body, status: status
      end

      def authenticate_api_key!
        raw_key = extract_api_key

        unless raw_key.present?
          render_error("invalid_api_key", message: "Missing API key", status: :unauthorized)
          return
        end

        @current_api_key = ApiKey.authenticate(raw_key)

        unless @current_api_key
          render_error("invalid_api_key", message: "Invalid or revoked API key", status: :unauthorized)
        end
      end

      def extract_api_key
        auth_header = request.headers["Authorization"]
        if auth_header&.start_with?("Bearer ")
          return auth_header.delete_prefix("Bearer ").strip
        end

        request.headers["X-Promptly-Key"]
      end

      def current_api_key
        @current_api_key
      end

      def current_workspace
        @current_workspace ||= current_api_key.workspace
      end

      def current_project
        @current_project
      end

      def set_current_project
        project_slug = request.headers["X-Promptly-Project"]

        unless project_slug.present?
          render_error("missing_project", message: "X-Promptly-Project header is required", status: :bad_request)
          return
        end

        @current_project = current_workspace.projects.find_by!(slug: project_slug)
      end
    end
  end
end
