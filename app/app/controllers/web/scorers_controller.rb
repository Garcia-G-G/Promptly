module Web
  class ScorersController < Web::BaseController
    before_action :set_scorer, only: [ :edit, :update, :destroy ]

    def index
      @scorers = Scorer.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .includes(:project)
        .order(updated_at: :desc)
    end

    def new
      @projects = @workspace.projects.order(:name)
      @scorer = Scorer.new(scorer_type: "llm_judge")
    end

    def create
      project = @workspace.projects.find(params.dig(:scorer, :project_id))
      @scorer = Scorers::Create.call(
        project: project,
        name: params.dig(:scorer, :name),
        scorer_type: params.dig(:scorer, :scorer_type),
        content: params.dig(:scorer, :content),
        model_hint: params.dig(:scorer, :model_hint).presence || PromptVersion::DEFAULT_MODEL_HINT
      )
      redirect_to workspace_web_scorers_path(@workspace.slug),
        notice: "Scorer '#{@scorer.name}' created."
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      @projects = @workspace.projects.order(:name)
      @scorer = Scorer.new(
        name: params.dig(:scorer, :name),
        scorer_type: params.dig(:scorer, :scorer_type).presence || "llm_judge",
        content: params.dig(:scorer, :content)
      )
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_entity
    end

    def edit
      @projects = @workspace.projects.order(:name)
    end

    def update
      @scorer.assign_attributes(scorer_update_params)
      @scorer.version_number = @scorer.version_number.to_i + 1 if content_or_type_changed?

      if @scorer.save
        redirect_to workspace_web_scorers_path(@workspace.slug),
          notice: "Scorer '#{@scorer.name}' updated (v#{@scorer.version_number})."
      else
        @projects = @workspace.projects.order(:name)
        flash.now[:alert] = @scorer.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @scorer.destroy!
      redirect_to workspace_web_scorers_path(@workspace.slug), notice: "Scorer deleted."
    end

    private

    def set_scorer
      @scorer = Scorer.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .find(params[:id])
    end

    def scorer_update_params
      params.require(:scorer).permit(:name, :scorer_type, :content, :model_hint, :active)
    end

    def content_or_type_changed?
      @scorer.content_changed? || @scorer.scorer_type_changed?
    end
  end
end
