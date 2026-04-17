module Prompts
  class Create
    def self.call(project:, slug:, description: nil)
      project.prompts.create!(slug: slug, description: description)
    end
  end
end
