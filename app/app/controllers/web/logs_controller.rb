module Web
  class LogsController < Web::BaseController
    def index
      @logs = Log.joins(project: :workspace)
        .where(workspaces: { id: @workspace.id })
        .order(created_at: :desc)
        .limit(100)
    end
  end
end
