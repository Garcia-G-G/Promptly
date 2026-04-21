module Web
  class DatasetsController < Web::BaseController
    def index
      @datasets = Dataset.joins(project: :workspace)
        .where(workspaces: { id: @workspace.id })
        .order(created_at: :desc)
    end
  end
end
