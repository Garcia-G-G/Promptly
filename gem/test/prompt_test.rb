# frozen_string_literal: true

require_relative "test_helper"

class PromptTest < Minitest::Test
  def build_prompt(overrides = {})
    defaults = {
      slug: "test-prompt",
      content: "Hello {name}, summarize in {language}",
      version: 1,
      version_id: 10,
      environment: "production",
      experiment: nil,
      variant: nil,
      model_hint: "claude-sonnet-4-6",
      variables: { name: "World", language: "English" },
      request_id: "req_123"
    }
    Promptly::Prompt.new(**defaults.merge(overrides))
  end

  def test_to_s_interpolates_variables
    prompt = build_prompt
    assert_equal "Hello World, summarize in English", prompt.to_s
  end

  def test_to_s_without_variables
    prompt = build_prompt(variables: {})
    assert_equal "Hello {name}, summarize in {language}", prompt.to_s
  end

  def test_experiment_returns_false_when_nil
    prompt = build_prompt(experiment: nil)
    refute prompt.experiment?
  end

  def test_experiment_returns_true_when_set
    prompt = build_prompt(experiment: "tone-tweak")
    assert prompt.experiment?
  end

  def test_to_h
    prompt = build_prompt
    hash = prompt.to_h
    assert_equal "test-prompt", hash[:slug]
    assert_equal 1, hash[:version]
    assert_equal "production", hash[:environment]
  end
end
