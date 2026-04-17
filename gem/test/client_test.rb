# frozen_string_literal: true

require_relative "test_helper"

class ClientTest < Minitest::Test
  include PromptlyTestHelper

  def test_successful_post
    stub_request(:post, "http://localhost:4000/api/v1/prompts/test/resolve")
      .with(
        headers: {
          "Authorization" => "Bearer test_key_123",
          "X-Promptly-Project" => "test-project",
          "Content-Type" => "application/json"
        }
      )
      .to_return(status: 200, body: '{"content": "hello"}', headers: { "Content-Type" => "application/json" })

    client = Promptly::Client.new(Promptly.configuration)
    result = client.post("/api/v1/prompts/test/resolve", { environment: "dev" })
    assert_equal "hello", result["content"]
  end

  def test_authentication_error
    stub_request(:post, "http://localhost:4000/api/v1/prompts/test/resolve")
      .to_return(status: 401, body: '{"error": "invalid key"}')

    client = Promptly::Client.new(Promptly.configuration)
    assert_raises(Promptly::AuthenticationError) do
      client.post("/api/v1/prompts/test/resolve", {})
    end
  end

  def test_not_found_error
    stub_request(:post, "http://localhost:4000/api/v1/prompts/missing/resolve")
      .to_return(status: 404, body: '{"error": "not found"}')

    client = Promptly::Client.new(Promptly.configuration)
    assert_raises(Promptly::NotFoundError) do
      client.post("/api/v1/prompts/missing/resolve", {})
    end
  end

  def test_rate_limit_error
    stub_request(:post, "http://localhost:4000/api/v1/prompts/test/resolve")
      .to_return(status: 429, body: '{"error": "rate limited"}', headers: { "Retry-After" => "60" })

    client = Promptly::Client.new(Promptly.configuration)
    assert_raises(Promptly::RateLimitError) do
      client.post("/api/v1/prompts/test/resolve", {})
    end
  end

  def test_server_error
    stub_request(:post, "http://localhost:4000/api/v1/prompts/test/resolve")
      .to_return(status: 500, body: '{"error": "internal"}')

    client = Promptly::Client.new(Promptly.configuration)
    assert_raises(Promptly::ServerError) do
      client.post("/api/v1/prompts/test/resolve", {})
    end
  end

  def test_sends_correct_headers
    stub_request(:post, "http://localhost:4000/api/v1/prompts/test/resolve")
      .to_return(status: 200, body: '{}')

    client = Promptly::Client.new(Promptly.configuration)
    client.post("/api/v1/prompts/test/resolve", {})

    assert_requested(:post, "http://localhost:4000/api/v1/prompts/test/resolve",
      headers: {
        "User-Agent" => "promptly-ruby/#{Promptly::VERSION}",
        "Authorization" => "Bearer test_key_123",
        "X-Promptly-Project" => "test-project"
      })
  end
end
