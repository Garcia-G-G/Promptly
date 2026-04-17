require "test_helper"

class PromptTest < ActiveSupport::TestCase
  test "valid prompt" do
    prompt = Prompt.new(project: projects(:playground), slug: "test-prompt")
    assert prompt.valid?
  end

  test "requires slug" do
    prompt = Prompt.new(project: projects(:playground), slug: nil)
    assert_not prompt.valid?
  end

  test "slug uniqueness scoped to project" do
    assert_raises ActiveRecord::RecordInvalid do
      Prompt.create!(project: projects(:playground), slug: "doc-summarizer")
    end
  end

  test "slug format validation" do
    prompt = Prompt.new(project: projects(:playground), slug: "INVALID SLUG!")
    assert_not prompt.valid?
  end

  test "normalizes slug" do
    prompt = Prompt.new(project: projects(:playground), slug: "  My-Slug  ")
    assert_equal "my-slug", prompt.slug
  end
end
