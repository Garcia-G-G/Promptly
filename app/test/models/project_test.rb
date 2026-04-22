require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  setup do
    @workspace = workspaces(:demo)
  end

  test "requires name" do
    project = Project.new(workspace: @workspace, slug: "test-#{SecureRandom.hex(3)}")
    assert_not project.valid?
    assert_includes project.errors[:name], "can't be blank"
  end

  test "requires unique slug per workspace" do
    existing = projects(:playground)
    duplicate = Project.new(workspace: existing.workspace, name: "Duplicate", slug: existing.slug)
    assert_not duplicate.valid?
  end

  test "prompts_count counter cache increments on prompt create" do
    project = projects(:playground)
    initial = project.reload.prompts_count
    project.prompts.create!(slug: "counter-test-#{SecureRandom.hex(4)}")
    assert_equal initial + 1, project.reload.prompts_count
  end
end
