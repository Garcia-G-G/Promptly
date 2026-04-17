require "test_helper"

class Experiments::CreateTest < ActiveSupport::TestCase
  test "creates a draft experiment" do
    prompt = prompts(:doc_summarizer)
    exp = Experiments::Create.call(
      prompt: prompt,
      name: "create-test",
      variant_a_version_id: prompt_versions(:doc_summarizer_production).id,
      variant_b_version_id: prompt_versions(:doc_summarizer_dev).id
    )
    assert exp.persisted?
    assert_equal "draft", exp.status
    assert_equal 50, exp.traffic_split
  end
end
