module Api
  module V1
    class SecurityScansController < BaseController
      before_action :set_current_project
      before_action :set_prompt_version

      def show
        scan = @prompt_version.security_scans.order(created_at: :desc).first

        if scan
          render json: Serializers::SecurityScanSerializer.call(scan)
        else
          render json: { error: "no_scan_found", message: "No security scan exists for this version" }, status: :not_found
        end
      end

      def create
        scan = SecurityScans::Run.call(prompt_version: @prompt_version)
        render json: Serializers::SecurityScanSerializer.call(scan), status: :created
      end

      private

      def set_prompt_version
        @prompt_version = PromptVersion.joins(prompt: :project)
          .where(projects: { id: current_project.id })
          .find(params[:prompt_version_id])
      end
    end
  end
end
