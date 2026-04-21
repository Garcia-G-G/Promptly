module Web
  class ScorersController < Web::BaseController
    def index
      @scorers = Scorer.joins(project: :workspace)
        .where(workspaces: { id: @workspace.id })
        .order(:name)
    end
  end
end
