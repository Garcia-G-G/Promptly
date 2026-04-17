class MarketingController < ApplicationController
  skip_before_action :authenticate_user!
  layout "landing"

  def index
    if user_signed_in?
      workspace = current_user.workspaces.first
      redirect_to workspace_path(workspace.slug) if workspace
    end
  end
end
