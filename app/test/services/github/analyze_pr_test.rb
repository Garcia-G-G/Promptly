require "test_helper"

class Github::AnalyzePrTest < ActiveSupport::TestCase
  setup do
    @workspace = workspaces(:demo)
    @installation = GithubInstallation.create!(
      workspace: @workspace,
      installation_id: 12345,
      repo_full_name: "org/repo"
    )
  end

  test "detects prompt-related files" do
    service = Github::AnalyzePr.new(@installation, "org/repo", 1, [])
    assert service.send(:prompt_related?, "prompts/doc-summarizer.yml")
    assert service.send(:prompt_related?, "app/prompts/test.rb")
    assert_not service.send(:prompt_related?, "app/models/user.rb")
  end

  test "returns nil when no prompt files" do
    result = Github::AnalyzePr.call(
      installation: @installation,
      repo: "org/repo",
      pr_number: 1,
      files: [ { filename: "app/models/user.rb", additions: 5, deletions: 2 } ]
    )
    assert_nil result
  end

  test "builds comment for prompt files" do
    result = Github::AnalyzePr.call(
      installation: @installation,
      repo: "org/repo",
      pr_number: 1,
      files: [ { filename: "prompts/doc-summarizer.yml", additions: 3, deletions: 1 } ]
    )
    assert_not_nil result
    assert_includes result, "Prompt Changes Detected"
    assert_includes result, "doc-summarizer.yml"
  end
end
