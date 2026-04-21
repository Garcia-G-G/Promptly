module Web
  class PromptVersionsController < Web::BaseController
    before_action :set_prompt

    def new
      @current_version = @prompt.prompt_versions.order(version_number: :desc).first
    end

    def create
      content = params.dig(:prompt_version, :content).to_s

      version = PromptVersions::Push.call(
        prompt: @prompt,
        content: content,
        variables: extract_variables(content),
        model_hint: params.dig(:prompt_version, :model_hint).presence || PromptVersion::DEFAULT_MODEL_HINT,
        created_by: current_user,
        created_via: :ui,
        parent_version: @prompt.prompt_versions.order(version_number: :desc).first
      )

      redirect_to workspace_web_prompt_path(@workspace.slug, @prompt.slug),
        notice: "Version #{version.version_number} pushed."
    rescue ActiveRecord::RecordInvalid => e
      @current_version = @prompt.prompt_versions.order(version_number: :desc).first
      flash.now[:alert] = e.record.errors.full_messages.to_sentence.presence || "Failed to push version."
      render :new, status: :unprocessable_entity
    end

    private

    def set_prompt
      @prompt = Prompt.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .find_by!(slug: params[:prompt_slug])
    end

    def extract_variables(content)
      content.scan(/\{([a-z_][a-z0-9_]*)\}/i).flatten.uniq.map { |name| { "name" => name } }
    end
  end
end
