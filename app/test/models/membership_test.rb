require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  setup do
    @owner = users(:owner)
    @workspace = Workspace.create!(name: "Test", slug: "test-membership", owner: @owner)
  end

  test "valid membership" do
    membership = Membership.new(workspace: @workspace, user: @owner, role: :owner)
    assert membership.valid?
  end

  test "valid roles" do
    %w[owner admin developer viewer].each do |role|
      membership = Membership.new(workspace: @workspace, user: @owner, role: role)
      assert membership.valid?, "Expected role '#{role}' to be valid"
    end
  end

  test "rejects invalid role" do
    assert_raises ArgumentError do
      Membership.new(workspace: @workspace, user: @owner, role: :superadmin)
    end
  end

  test "unique user per workspace" do
    Membership.create!(workspace: @workspace, user: @owner, role: :owner)
    duplicate = Membership.new(workspace: @workspace, user: @owner, role: :developer)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "same user can be in different workspaces" do
    other_workspace = Workspace.create!(name: "Other", slug: "other", owner: @owner)
    Membership.create!(workspace: @workspace, user: @owner, role: :owner)
    membership = Membership.new(workspace: other_workspace, user: @owner, role: :owner)
    assert membership.valid?
  end

  test "belongs to workspace" do
    membership = Membership.create!(workspace: @workspace, user: @owner, role: :owner)
    assert_equal @workspace, membership.workspace
  end

  test "belongs to user" do
    membership = Membership.create!(workspace: @workspace, user: @owner, role: :owner)
    assert_equal @owner, membership.user
  end
end
