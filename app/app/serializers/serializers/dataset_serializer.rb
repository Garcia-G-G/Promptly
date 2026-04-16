module Serializers
  class DatasetSerializer
    def self.call(dataset)
      {
        id: dataset.id,
        name: dataset.name,
        description: dataset.description,
        row_count: dataset.respond_to?(:row_count) ? dataset.row_count : dataset.dataset_rows.count,
        created_at: dataset.created_at.iso8601
      }
    end
  end
end
