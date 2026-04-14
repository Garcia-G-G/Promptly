class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  helper_method :current_workspace

  private

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
