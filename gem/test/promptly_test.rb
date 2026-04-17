# frozen_string_literal: true

require_relative "test_helper"

class PromptlyTest < Minitest::Test
  include PromptlyTestHelper

  RESOLVE_RESPONSE = {
    content: "Summarize this in {language}",
    version_number: 3,
    version_id: 42,
    environment: "production",
    experiment: "tone-tweak",
    variant: "b",
    model_hint: "claude-sonnet-4-6"
  }.to_json

  def test_get_returns_prompt
    stub_request(:post, "http://localhost:4000/api/v1/prompts/doc-summarizer/resolve")
      .to_return(status: 200, body: RESOLVE_RESPONSE)

    prompt = Promptly.get("doc-summarizer", vars: { language: "Spanish" })

    assert_instance_of Promptly::Prompt, prompt
    assert_equal "doc-summarizer", prompt.slug
    assert_equal "Summarize this in {language}", prompt.content
    assert_equal 3, prompt.version
    assert_equal "tone-tweak", prompt.experiment
    assert_equal "b", prompt.variant
    assert prompt.experiment?
  end

  def test_get_interpolates_variables
    stub_request(:post, "http://localhost:4000/api/v1/prompts/doc-summarizer/resolve")
      .to_return(status: 200, body: RESOLVE_RESPONSE)

    prompt = Promptly.get("doc-summarizer", vars: { language: "Spanish" })
    assert_equal "Summarize this in Spanish", prompt.to_s
  end

  def test_get_sends_correct_payload
    stub_request(:post, "http://localhost:4000/api/v1/prompts/doc-summarizer/resolve")
      .to_return(status: 200, body: RESOLVE_RESPONSE)

    Promptly.get("doc-summarizer", vars: { language: "es" }, env: :staging, request_id: "req_abc")

    assert_requested(:post, "http://localhost:4000/api/v1/prompts/doc-summarizer/resolve") do |req|
      body = JSON.parse(req.body)
      body["environment"] == "staging" &&
        body["request_id"] == "req_abc" &&
        body["variables"]["language"] == "es"
    end
  end

  def test_log_sends_output
    stub_request(:post, "http://localhost:4000/api/v1/prompts/doc-summarizer/log")
      .to_return(status: 202, body: '{"accepted": true, "log_id": 1}')

    result = Promptly.log(
      prompt_slug: "doc-summarizer",
      output: "The summary is...",
      latency_ms: 230,
      tokens: { prompt: 1200, completion: 340 },
      model_version: "claude-sonnet-4-6"
    )

    assert_equal true, result

    assert_requested(:post, "http://localhost:4000/api/v1/prompts/doc-summarizer/log") do |req|
      body = JSON.parse(req.body)
      body["output"] == "The summary is..." &&
        body["latency_ms"] == 230
    end
  end

  def test_with_block_resolves_and_logs
    stub_request(:post, "http://localhost:4000/api/v1/prompts/doc-summarizer/resolve")
      .to_return(status: 200, body: RESOLVE_RESPONSE)
    stub_request(:post, "http://localhost:4000/api/v1/prompts/doc-summarizer/log")
      .to_return(status: 202, body: '{"accepted": true, "log_id": 1}')

    result = Promptly.with("doc-summarizer", vars: { language: "es" }) do |prompt|
      "Generated output from #{prompt.slug}"
    end

    assert_equal "Generated output from doc-summarizer", result
    assert_requested(:post, "http://localhost:4000/api/v1/prompts/doc-summarizer/resolve")
    assert_requested(:post, "http://localhost:4000/api/v1/prompts/doc-summarizer/log")
  end

  def test_get_without_config_raises
    Promptly.reset!
    assert_raises(Promptly::ConfigurationError) do
      Promptly.get("doc-summarizer")
    end
  end
end
