module Datasets
  class ImportRows
    MAX_ROWS = 10_000
    BATCH_SIZE = 1_000

    def self.call(dataset:, rows:)
      raise ArgumentError, "Maximum #{MAX_ROWS} rows per import" if rows.size > MAX_ROWS
      return 0 if rows.empty?

      now = Time.current
      records = rows.map do |row|
        {
          dataset_id: dataset.id,
          input_vars: row[:input_vars] || row["input_vars"] || {},
          expected_output: row[:expected_output] || row["expected_output"],
          tags: row[:tags] || row["tags"] || [],
          created_at: now,
          updated_at: now
        }
      end

      # Batch inserts to avoid oversized SQL statements
      records.each_slice(BATCH_SIZE) do |batch|
        DatasetRow.insert_all(batch)
      end

      records.size
    end
  end
end
