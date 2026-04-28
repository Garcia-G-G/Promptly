module Web
  class ProjectPromptsController < Web::BaseController
    before_action :set_project

    def new
      @prompt = @project.prompts.build
    end

    def create
      @prompt = @project.prompts.build(prompt_attrs)

      ActiveRecord::Base.transaction do
        @prompt.save!
        content = params.dig(:prompt, :content).to_s
        PromptVersions::Push.call(
          prompt: @prompt,
          content: content,
          variables: PromptVariables.extract(content),
          model_hint: params.dig(:prompt, :model_hint).presence || PromptVersion::DEFAULT_MODEL_HINT,
          created_by: current_user,
          created_via: :ui
        )
      end

      redirect_to workspace_web_prompt_path(@workspace.slug, @prompt.slug),
        notice: "Prompt created."
    rescue ActiveRecord::RecordInvalid => e
      @prompt = @project.prompts.build(prompt_attrs)
      flash.now[:alert] = e.record.errors.full_messages.to_sentence.presence || "Failed to create prompt."
      render :new, status: :unprocessable_entity
    end

    private

    def set_project
      @project = @workspace.projects.find_by!(slug: params[:project_slug])
    end

    def prompt_attrs
      params.require(:prompt).permit(:slug, :description)
    end
  end
end
