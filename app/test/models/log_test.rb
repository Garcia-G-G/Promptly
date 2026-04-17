require "test_helper"

class LogTest < ActiveSupport::TestCase
  test "valid log" do
    log = Log.new(
      prompt: prompts(:doc_summarizer),
      prompt_version: prompt_versions(:doc_summarizer_production),
      project: projects(:playground),
      output: "A summary"
    )
    assert log.valid?
  end

  test "requires output" do
    log = Log.new(
      prompt: prompts(:doc_summarizer),
      prompt_version: prompt_versions(:doc_summarizer_production),
      project: projects(:playground),
      output: nil
    )
    assert_not log.valid?
  end

  test "no updated_at column" do
    assert_not Log.column_names.include?("updated_at")
  end
end
