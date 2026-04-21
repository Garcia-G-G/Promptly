module Web
  class PromptsController < Web::BaseController
    before_action :set_prompt, only: [ :show, :diff ]

    def index
      @prompts = Prompt.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .includes(:prompt_versions, :project)
        .order(updated_at: :desc)
    end

    def show
      @versions_by_env = @prompt.prompt_versions
        .where.not(environment: :archived)
        .index_by(&:environment)
      @current_version = @prompt.prompt_versions.order(version_number: :desc).first
    end

    def diff
      max_version = @prompt.prompt_versions.maximum(:version_number) || 1
      @v_old = @prompt.prompt_versions.find_by!(version_number: params[:from] || [ max_version - 1, 1 ].max)
      @v_new = @prompt.prompt_versions.find_by!(version_number: params[:to] || max_version)
    end

    private

    def set_prompt
      @prompt = Prompt.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .find_by!(slug: params[:slug])
    end
  end
end
