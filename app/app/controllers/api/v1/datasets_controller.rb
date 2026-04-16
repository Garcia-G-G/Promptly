module Api
  module V1
    class DatasetsController < BaseController
      before_action :set_current_project
      before_action :set_dataset, only: [ :show, :destroy, :import_rows ]

      def index
        datasets = current_project.datasets
          .left_joins(:dataset_rows)
          .select("datasets.*, COUNT(dataset_rows.id) AS row_count")
          .group("datasets.id")
          .order(:name)
        render json: datasets.map { |d| Serializers::DatasetSerializer.call(d) }
      end

      def create
        dataset = Datasets::Create.call(
          project: current_project,
          name: params.require(:name),
          description: params[:description]
        )
        render json: Serializers::DatasetSerializer.call(dataset), status: :created
      end

      def show
        render json: Serializers::DatasetSerializer.call(@dataset)
      end

      def destroy
        @dataset.destroy!
        head :no_content
      end

      def import_rows
        rows = parse_rows
        count = Datasets::ImportRows.call(dataset: @dataset, rows: rows)
        render json: { imported: count }, status: :created
      end

      private

      def set_dataset
        @dataset = current_project.datasets.find(params[:id])
      end

      def parse_rows
        if request.content_type&.include?("text/csv")
          parse_csv(request.body.read)
        else
          params.require(:rows).map(&:to_unsafe_h)
        end
      end

      def parse_csv(csv_string)
        require "csv"

        # Ensure valid UTF-8
        csv_string = csv_string.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")

        rows = []
        csv = CSV.parse(csv_string, headers: true)
        csv.each do |row|
          input_vars = {}
          expected_output = nil
          tags = []

          row.each do |header, value|
            next if header.nil?
            sanitized_value = sanitize_csv_value(value)

            case header.strip
            when "_expected_output"
              expected_output = sanitized_value
            when "_tags"
              tags = sanitized_value.to_s.split(",").map(&:strip).reject(&:empty?)
            else
              input_vars[header.strip] = sanitized_value.to_s
            end
          end

          rows << { input_vars: input_vars, expected_output: expected_output, tags: tags }
        end
        rows
      end

      # Strip leading formula characters to prevent CSV injection
      def sanitize_csv_value(value)
        return value unless value.is_a?(String)
        value.sub(/\A[=+\-@\t\r]/, "")
      end
    end
  end
end
