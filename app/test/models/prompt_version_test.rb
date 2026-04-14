require "test_helper"

class PromptVersionTest < ActiveSupport::TestCase
  test "computes content_hash on create" do
    prompt = Prompt.create!(project: projects(:playground), slug: "hash-test")
    version = PromptVersion.create!(prompt: prompt, content: "Hello world", created_via: :api)
    assert_equal Digest::SHA256.hexdigest("Hello world"), version.content_hash
  end

  test "auto-assigns version_number starting at 1" do
    prompt = Prompt.create!(project: projects(:playground), slug: "autonum-test")
    v1 = PromptVersion.create!(prompt: prompt, content: "v1", created_via: :api)
    assert_equal 1, v1.version_number
  end

  test "auto-increments version_number" do
    prompt = Prompt.create!(project: projects(:playground), slug: "increment-test")
    PromptVersion.create!(prompt: prompt, content: "v1", created_via: :api)
    v2 = PromptVersion.create!(prompt: prompt, content: "v2", created_via: :api, environment: :staging)
    assert_equal 2, v2.version_number
  end

  test "version_number unique per prompt" do
    prompt = Prompt.create!(project: projects(:playground), slug: "unique-ver-test")
    PromptVersion.create!(prompt: prompt, content: "v1", version_number: 1, created_via: :api)
    assert_raises ActiveRecord::RecordInvalid do
      PromptVersion.create!(prompt: prompt, content: "v2", version_number: 1, created_via: :api, environment: :staging)
    end
  end

  test "environment enum values" do
    prompt = Prompt.create!(project: projects(:playground), slug: "env-test")
    version = PromptVersion.create!(prompt: prompt, content: "test", environment: :dev, created_via: :api)
    assert version.dev?
    version.update!(environment: :staging)
    assert version.staging?
  end

  test "partial unique index allows multiple archived versions" do
    prompt = Prompt.create!(project: projects(:playground), slug: "archive-test")
    PromptVersion.create!(prompt: prompt, content: "old1", environment: :archived, created_via: :api)
    v2 = PromptVersion.create!(prompt: prompt, content: "old2", environment: :archived, created_via: :api)
    assert v2.persisted?
  end

  test "partial unique index prevents two non-archived versions in same env" do
    prompt = Prompt.create!(project: projects(:playground), slug: "dup-env-test")
    PromptVersion.create!(prompt: prompt, content: "first", environment: :dev, created_via: :api)
    assert_raises ActiveRecord::RecordNotUnique do
      PromptVersion.create!(prompt: prompt, content: "second", environment: :dev, created_via: :api, version_number: 99)
    end
  end

  test "requires content" do
    prompt = Prompt.create!(project: projects(:playground), slug: "no-content-test")
    version = PromptVersion.new(prompt: prompt, content: nil, created_via: :api)
    assert_not version.valid?
  end
end
