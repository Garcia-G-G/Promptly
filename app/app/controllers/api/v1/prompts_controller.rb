module Api
  module V1
    class PromptsController < BaseController
      def resolve
        render json: { status: "not_implemented" }, status: :not_implemented
      end

      def log
        render json: { status: "not_implemented" }, status: :not_implemented
      end
    end
  end
end
