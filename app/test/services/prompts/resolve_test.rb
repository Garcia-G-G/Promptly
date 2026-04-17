require "test_helper"

class Prompts::ResolveTest < ActiveSupport::TestCase
  test "resolves production version" do
    result = Prompts::Resolve.call(
      project: projects(:playground),
      slug: "doc-summarizer",
      environment: "production"
    )
    assert_equal prompts(:doc_summarizer), result[:prompt]
    assert_equal prompt_versions(:doc_summarizer_production), result[:version]
  end

  test "resolves dev version" do
    result = Prompts::Resolve.call(
      project: projects(:playground),
      slug: "doc-summarizer",
      environment: "dev"
    )
    assert_equal prompt_versions(:doc_summarizer_dev), result[:version]
  end

  test "raises NotFound for unknown slug" do
    assert_raises Prompts::NotFound do
      Prompts::Resolve.call(project: projects(:playground), slug: "nonexistent")
    end
  end

  test "raises NoActiveVersion when no version in environment" do
    assert_raises Prompts::NoActiveVersion do
      Prompts::Resolve.call(project: projects(:playground), slug: "empty-prompt", environment: "production")
    end
  end
end
