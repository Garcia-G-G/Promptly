module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_key!

      private

      def authenticate_api_key!
        render json: { status: "not_implemented", error: "API key authentication not yet implemented" }, status: :not_implemented
      end
    end
  end
end
