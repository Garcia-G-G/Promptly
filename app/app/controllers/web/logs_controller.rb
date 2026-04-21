module Web
  class LogsController < Web::BaseController
    PER_PAGE = 50

    def index
      scope = Log.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .includes(:prompt, :prompt_version, :experiment)
        .order(created_at: :desc)

      scope = apply_filters(scope)

      # Stats computed off the filtered (but un-paginated) scope.
      @total_count = scope.count
      latencies = scope.where.not(latency_ms: nil)
      @avg_latency = latencies.average(:latency_ms)&.round(1)
      @avg_score = scope.where.not(score: nil).average(:score)&.round(3)
      @p95_latency = compute_p95(latencies, @total_count)

      @page = [ params[:page].to_i, 1 ].max
      @per_page = PER_PAGE
      @total_pages = [ (@total_count.to_f / @per_page).ceil, 1 ].max
      @logs = scope.offset((@page - 1) * @per_page).limit(@per_page)

      @prompts = Prompt.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .order(:slug)
    end

    def show
      @log = Log.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .includes(:prompt, :prompt_version, :experiment, :scorer)
        .find(params[:id])
      @tokens = parse_tokens(@log.tokens)
    end

    private

    def apply_filters(scope)
      scope = scope.where(prompt_id: params[:prompt_id]) if params[:prompt_id].present?
      scope = scope.where("logs.created_at >= ?", parse_date(params[:from]).beginning_of_day) if params[:from].present?
      scope = scope.where("logs.created_at <= ?", parse_date(params[:to]).end_of_day) if params[:to].present?
      scope = scope.where("logs.score >= ?", params[:min_score].to_f) if params[:min_score].present?
      scope = scope.where("logs.score <= ?", params[:max_score].to_f) if params[:max_score].present?
      scope = scope.where.not(experiment_id: nil) if params[:has_experiment] == "1"
      scope
    end

    def parse_date(value)
      Date.parse(value)
    rescue ArgumentError, TypeError
      Date.today
    end

    def compute_p95(latencies_scope, total)
      count = latencies_scope.count
      return nil if count.zero?

      offset = [ (count * 0.95).ceil - 1, 0 ].max
      latencies_scope.order(:latency_ms).offset(offset).limit(1).pick(:latency_ms)
    end

    def parse_tokens(tokens)
      return {} if tokens.blank?
      return tokens.symbolize_keys if tokens.is_a?(Hash)

      JSON.parse(tokens).symbolize_keys
    rescue JSON::ParserError
      {}
    end
  end
end
