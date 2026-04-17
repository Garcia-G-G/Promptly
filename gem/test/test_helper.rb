# frozen_string_literal: true

require "minitest/autorun"
require "webmock/minitest"
require "promptly"

module PromptlyTestHelper
  def setup
    Promptly.reset!
    Promptly.configure do |c|
      c.api_key = "test_key_123"
      c.project = "test-project"
      c.environment = :dev
      c.base_url = "http://localhost:4000"
    end
  end
end
