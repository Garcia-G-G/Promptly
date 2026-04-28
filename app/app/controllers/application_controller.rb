class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_sidebar_counts, if: :user_signed_in?

  layout :layout_by_resource

  helper_method :current_workspace

  private

  def layout_by_resource
    devise_controller? ? "landing" : "application"
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def set_sidebar_counts
    return unless current_workspace

    # Counter-cache backed sum — no COUNT(*) on prompts.
    @prompt_count = current_workspace.projects.sum(:prompts_count)

    # Running experiments flip relatively rarely; a 2-minute cache keeps
    # this off the hot path without making the sidebar visibly stale.
    @experiment_count = Rails.cache.fetch(
      "workspace:#{current_workspace.id}:running_experiments",
      expires_in: 2.minutes
    ) do
      Experiment.joins(prompt: { project: :workspace })
        .where(workspaces: { id: current_workspace.id })
        .where(status: :running)
        .count
    end
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
