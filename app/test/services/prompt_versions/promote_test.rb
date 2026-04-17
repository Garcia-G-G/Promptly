require "test_helper"

class PromptVersions::PromoteTest < ActiveSupport::TestCase
  setup do
    @prompt = Prompt.create!(project: projects(:playground), slug: "promote-test")
    @dev_version = PromptVersions::Push.call(prompt: @prompt, content: "Original content")
  end

  test "promotes to staging" do
    promoted = PromptVersions::Promote.call(prompt_version: @dev_version, to_environment: :staging)
    assert promoted.persisted?
    assert_equal "staging", promoted.environment
    assert_equal @dev_version.content, promoted.content
    assert_equal @dev_version.content_hash, promoted.content_hash
  end

  test "promotes to production" do
    promoted = PromptVersions::Promote.call(prompt_version: @dev_version, to_environment: :production)
    assert_equal "production", promoted.environment
  end

  test "archives previous version in target environment" do
    first_promoted = PromptVersions::Promote.call(prompt_version: @dev_version, to_environment: :staging)

    # Push a new dev version and promote it
    @dev_version.update!(environment: :archived)
    new_dev = PromptVersions::Push.call(prompt: @prompt, content: "Updated content")
    second_promoted = PromptVersions::Promote.call(prompt_version: new_dev, to_environment: :staging)

    first_promoted.reload
    assert_equal "archived", first_promoted.environment
    assert_equal "staging", second_promoted.environment
  end

  test "rejects promotion to dev" do
    assert_raises ArgumentError do
      PromptVersions::Promote.call(prompt_version: @dev_version, to_environment: :dev)
    end
  end

  test "rejects promotion to archived" do
    assert_raises ArgumentError do
      PromptVersions::Promote.call(prompt_version: @dev_version, to_environment: :archived)
    end
  end

  test "sets parent_version on promoted version" do
    promoted = PromptVersions::Promote.call(prompt_version: @dev_version, to_environment: :staging)
    assert_equal @dev_version, promoted.parent_version
  end
end
