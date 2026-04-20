class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  layout :layout_by_resource

  helper_method :current_workspace

  private

  def layout_by_resource
    devise_controller? ? "landing" : "application"
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def current_workspace
    return @current_workspace if defined?(@current_workspace)

    slug = params[:workspace_slug] || params[:slug]
    return nil unless slug

    @current_workspace = current_user
      .workspaces
      .find_by!(slug: slug)
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, "Not Found"
  end
end
