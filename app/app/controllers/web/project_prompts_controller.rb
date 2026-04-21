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
        PromptVersions::Push.call(
          prompt: @prompt,
          content: params.dig(:prompt, :content).to_s,
          variables: extract_variables(params.dig(:prompt, :content).to_s),
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

    # Extract `{variable_name}` tokens from the content into the shape
    # PromptVersions::Push expects (an array of { "name" => ... } hashes).
    def extract_variables(content)
      content.scan(/\{([a-z_][a-z0-9_]*)\}/i).flatten.uniq.map { |name| { "name" => name } }
    end
  end
end
