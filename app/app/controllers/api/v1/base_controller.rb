module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_key!

      rescue_from ActiveRecord::RecordNotFound do |e|
        render json: { error: "not_found" }, status: :not_found
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { error: "validation_failed", details: e.record.errors.as_json }, status: :unprocessable_entity
      end

      rescue_from ActionController::ParameterMissing do |e|
        render json: { error: "missing_parameter", parameter: e.param.to_s }, status: :bad_request
      end

      rescue_from Prompts::NotFound do |e|
        render json: { error: "not_found", message: e.message }, status: :not_found
      end

      rescue_from Prompts::NoActiveVersion do |e|
        render json: { error: "no_active_version", message: e.message }, status: :not_found
      end

      private

      def authenticate_api_key!
        raw_key = extract_api_key
        @current_api_key = ApiKey.authenticate(raw_key)

        unless @current_api_key
          render json: { error: "invalid_api_key" }, status: :unauthorized
        end
      end

      def extract_api_key
        # Try Authorization: Bearer <key> first
        auth_header = request.headers["Authorization"]
        if auth_header&.start_with?("Bearer ")
          return auth_header.delete_prefix("Bearer ").strip
        end

        # Fallback to X-Promptly-Key header
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
          render json: { error: "missing_project" }, status: :bad_request
          return
        end

        @current_project = current_workspace.projects.find_by!(slug: project_slug)
      end
    end
  end
end
