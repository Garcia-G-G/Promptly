class ProjectsController < ApplicationController
  before_action :set_workspace

  def index
    @projects = @workspace.projects.order(:name)
  end

  def show
    @project = @workspace.projects.find_by!(slug: params[:slug])
  end

  def new
    @project = @workspace.projects.build
  end

  def create
    @project = @workspace.projects.build(project_params)

    if @project.save
      redirect_to workspace_project_path(@workspace.slug, @project.slug), notice: "Project created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_workspace
    @workspace = current_workspace
  end

  def project_params
    params.require(:project).permit(:name, :slug)
  end
end
