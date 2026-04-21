module Web
  class ExperimentsController < Web::BaseController
    def index
      @experiments = Experiment.joins(prompt: { project: :workspace })
        .where(workspaces: { id: @workspace.id })
        .includes(prompt: :project)
        .order(created_at: :desc)
    end
  end
end
