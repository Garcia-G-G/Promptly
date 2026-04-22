class MarketingController < ApplicationController
  skip_before_action :authenticate_user!
  layout "landing"

  def index
    return unless user_signed_in?

    # Signed-in users should never see the public landing page. Route
    # them to their first workspace, or to the create-workspace form
    # if they don't have one yet (e.g. just signed up).
    workspace = current_user.workspaces.first
    if workspace
      redirect_to workspace_path(workspace.slug)
    else
      redirect_to new_workspace_path,
        notice: "Welcome to Promptly! Create your first workspace to get started."
    end
  end
end
