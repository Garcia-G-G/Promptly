ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    private

    def api_headers(raw_key: "pk_test_key_for_fixtures_only", project_slug: "playground")
      headers = { "Authorization" => "Bearer #{raw_key}", "Content-Type" => "application/json" }
      headers["X-Promptly-Project"] = project_slug if project_slug
      headers
    end
  end
end
