class WorkspacesController < ApplicationController
  def new
    @workspace = Workspace.new
  end

  def create
    @workspace = Workspace.new(workspace_params)
    @workspace.owner = current_user

    ActiveRecord::Base.transaction do
      if @workspace.save
        Membership.create!(workspace: @workspace, user: current_user, role: :owner)
        redirect_to workspace_path(@workspace.slug), notice: "Workspace created."
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def show
    @workspace = current_workspace
    @projects = @workspace.projects.order(:name)
  end

  private

  def workspace_params
    params.require(:workspace).permit(:name, :slug)
  end
end
