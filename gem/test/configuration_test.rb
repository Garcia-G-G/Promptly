# frozen_string_literal: true

require_relative "test_helper"

class ConfigurationTest < Minitest::Test
  include PromptlyTestHelper

  def test_defaults_from_env
    Promptly.reset!
    config = Promptly::Configuration.new
    assert_equal "dev", config.environment.to_s
    assert_equal "https://api.promptly.dev", config.base_url
    assert_equal 5, config.timeout
    assert_equal false, config.otel_enabled
  end

  def test_configure_block
    Promptly.configure do |c|
      c.api_key = "my_key"
      c.project = "my-project"
      c.environment = :production
    end
    assert_equal "my_key", Promptly.configuration.api_key
    assert_equal "my-project", Promptly.configuration.project
    assert_equal :production, Promptly.configuration.environment
  end

  def test_validate_missing_api_key
    Promptly.reset!
    assert_raises(Promptly::ConfigurationError) do
      Promptly.configuration.validate!
    end
  end

  def test_validate_missing_project
    Promptly.reset!
    Promptly.configure { |c| c.api_key = "key" }
    assert_raises(Promptly::ConfigurationError) do
      Promptly.configuration.validate!
    end
  end
end
