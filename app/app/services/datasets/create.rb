module Datasets
  class Create
    def self.call(project:, name:, description: nil)
      project.datasets.create!(name: name, description: description)
    end
  end
end
