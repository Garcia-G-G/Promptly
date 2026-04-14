require "test_helper"

class Prompts::CreateTest < ActiveSupport::TestCase
  test "creates a prompt" do
    prompt = Prompts::Create.call(project: projects(:playground), slug: "new-prompt", description: "A test")
    assert prompt.persisted?
    assert_equal "new-prompt", prompt.slug
    assert_equal "A test", prompt.description
  end

  test "raises on duplicate slug" do
    assert_raises ActiveRecord::RecordInvalid do
      Prompts::Create.call(project: projects(:playground), slug: "doc-summarizer")
    end
  end
end
