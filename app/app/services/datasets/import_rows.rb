module Datasets
  class ImportRows
    MAX_ROWS = 10_000

    def self.call(dataset:, rows:)
      raise ArgumentError, "Maximum #{MAX_ROWS} rows per import" if rows.size > MAX_ROWS

      records = rows.map do |row|
        {
          dataset_id: dataset.id,
          input_vars: row[:input_vars] || row["input_vars"] || {},
          expected_output: row[:expected_output] || row["expected_output"],
          tags: row[:tags] || row["tags"] || [],
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      DatasetRow.insert_all(records) if records.any?
      records.size
    end
  end
end
