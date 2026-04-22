require "csv"

module Web
  class DatasetsController < Web::BaseController
    PER_PAGE = 100

    before_action :set_dataset, only: [ :show, :destroy, :import ]

    def index
      @datasets = Dataset.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .includes(:project, :dataset_rows)
        .order(updated_at: :desc)
    end

    def show
      @current_page = [ params[:page].to_i, 1 ].max
      offset = (@current_page - 1) * PER_PAGE
      rows = @dataset.dataset_rows.order(:id).offset(offset).limit(PER_PAGE + 1).to_a
      @has_more = rows.size > PER_PAGE
      @rows = rows.first(PER_PAGE)
    end

    def new
      @projects = @workspace.projects.order(:name)
      @dataset = Dataset.new
    end

    def create
      project = @workspace.projects.find(params.dig(:dataset, :project_id))
      @dataset = Datasets::Create.call(
        project: project,
        name: params.dig(:dataset, :name),
        description: params.dig(:dataset, :description)
      )

      initial_rows = extract_rows_from_params(params[:dataset])
      Datasets::ImportRows.call(dataset: @dataset, rows: initial_rows) if initial_rows.any?

      redirect_to workspace_web_dataset_path(@workspace.slug, @dataset), notice: "Dataset created."
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      @projects = @workspace.projects.order(:name)
      @dataset = Dataset.new(name: params.dig(:dataset, :name), description: params.dig(:dataset, :description))
      flash.now[:alert] = e.message
      render :new, status: :unprocessable_entity
    end

    def destroy
      @dataset.destroy!
      redirect_to workspace_web_datasets_path(@workspace.slug), notice: "Dataset deleted."
    end

    def import
      rows = extract_rows_from_params(params)
      if rows.any?
        count = Datasets::ImportRows.call(dataset: @dataset, rows: rows)
        redirect_to workspace_web_dataset_path(@workspace.slug, @dataset),
          notice: "#{count} rows imported."
      else
        redirect_to workspace_web_dataset_path(@workspace.slug, @dataset),
          alert: "No valid rows found in import."
      end
    rescue ArgumentError, CSV::MalformedCSVError => e
      redirect_to workspace_web_dataset_path(@workspace.slug, @dataset), alert: e.message
    end

    private

    def set_dataset
      @dataset = Dataset.joins(:project)
        .where(projects: { workspace_id: @workspace.id })
        .find(params[:id])
    end

    def extract_rows_from_params(source)
      if source[:csv_file].present?
        parse_csv(source[:csv_file])
      elsif source[:json_rows].present?
        parse_json_rows(source[:json_rows])
      else
        []
      end
    end

    def parse_csv(file)
      rows = []
      CSV.foreach(file.path, headers: true) do |row|
        hash = row.to_h
        input_vars = hash.except("expected_output", "tags")
        tags = hash["tags"].present? ? hash["tags"].split(";").map(&:strip) : []
        rows << { input_vars: input_vars, expected_output: hash["expected_output"], tags: tags }
      end
      rows
    end

    def parse_json_rows(json_string)
      parsed = JSON.parse(json_string)
      parsed = [ parsed ] unless parsed.is_a?(Array)
      parsed.map do |row|
        {
          input_vars: row["input_vars"] || row.except("expected_output", "tags"),
          expected_output: row["expected_output"],
          tags: row["tags"] || []
        }
      end
    rescue JSON::ParserError
      []
    end
  end
end
