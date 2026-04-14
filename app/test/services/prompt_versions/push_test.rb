require "test_helper"

class PromptVersions::PushTest < ActiveSupport::TestCase
  setup do
    @prompt = Prompt.create!(project: projects(:playground), slug: "push-test")
  end

  test "creates version in dev environment" do
    version = PromptVersions::Push.call(prompt: @prompt, content: "Hello")
    assert version.persisted?
    assert_equal "dev", version.environment
    assert_equal 1, version.version_number
  end

  test "increments version number across pushes" do
    PromptVersions::Push.call(prompt: @prompt, content: "v1")
    # Archive the dev version first so we can push another to dev
    @prompt.prompt_versions.find_by(environment: :dev).update!(environment: :archived)
    v2 = PromptVersions::Push.call(prompt: @prompt, content: "v2")
    assert_equal 2, v2.version_number
  end

  test "computes content_hash" do
    version = PromptVersions::Push.call(prompt: @prompt, content: "test content")
    assert_equal Digest::SHA256.hexdigest("test content"), version.content_hash
  end

  test "stores variables" do
    vars = [{ "name" => "lang", "default" => "en" }]
    version = PromptVersions::Push.call(prompt: @prompt, content: "Hello", variables: vars)
    assert_equal vars, version.variables
  end
end
