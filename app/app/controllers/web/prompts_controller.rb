module Web
  class PromptsController < Web::BaseController
    before_action :set_prompt, only: [ :show, :diff, :promote ]

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
      @all_versions = @prompt.prompt_versions
        .includes(:created_by)
        .order(version_number: :desc)
    end

    def diff
      max_version = @prompt.prompt_versions.maximum(:version_number) || 1
      @v_old = @prompt.prompt_versions.find_by!(version_number: params[:from] || [ max_version - 1, 1 ].max)
      @v_new = @prompt.prompt_versions.find_by!(version_number: params[:to] || max_version)
    end

    def promote
      version = @prompt.prompt_versions.find(params[:version_id])
      PromptVersions::Promote.call(
        prompt_version: version,
        to_environment: params[:to_environment]
      )
      redirect_to workspace_web_prompt_path(@workspace.slug, @prompt.slug),
        notice: "v#{version.version_number} promoted to #{params[:to_environment]}."
    rescue PromptVersions::SecurityBlocked, ArgumentError => e
      redirect_to workspace_web_prompt_path(@workspace.slug, @prompt.slug), alert: e.message
    end

    private

    def set_prompt
      @prompt = Prompt.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .find_by!(slug: params[:slug])
    end
  end
end
