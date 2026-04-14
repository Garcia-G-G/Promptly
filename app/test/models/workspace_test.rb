require "test_helper"

class WorkspaceTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(
      email: "owner@test.com",
      password: "password123456",
      name: "Test Owner"
    )
    @owner.confirm
  end

  test "valid workspace" do
    workspace = Workspace.new(name: "My Workspace", slug: "my-workspace", owner: @owner)
    assert workspace.valid?
  end

  test "requires slug" do
    workspace = Workspace.new(name: "My Workspace", slug: nil, owner: @owner)
    assert_not workspace.valid?
    assert_includes workspace.errors[:slug], "can't be blank"
  end

  test "requires unique slug" do
    Workspace.create!(name: "First", slug: "taken", owner: @owner)
    workspace = Workspace.new(name: "Second", slug: "taken", owner: @owner)
    assert_not workspace.valid?
    assert_includes workspace.errors[:slug], "has already been taken"
  end

  test "slug format allows lowercase alphanumeric and hyphens" do
    valid_slugs = %w[my-workspace workspace1 a-b-c-123]
    valid_slugs.each do |slug|
      workspace = Workspace.new(name: "Test", slug: slug, owner: @owner)
      assert workspace.valid?, "Expected '#{slug}' to be valid"
    end
  end

  test "slug format rejects invalid characters" do
    # Note: uppercase slugs are normalized to lowercase before validation,
    # so "UPPER" becomes "upper" (valid). Test only truly invalid characters.
    invalid_slugs = [ "under_score", "special!", "slug with spaces" ]
    invalid_slugs.each do |slug|
      workspace = Workspace.new(name: "Test", slug: slug, owner: @owner)
      assert_not workspace.valid?, "Expected '#{slug}' to be invalid"
    end
  end

  test "normalizes uppercase slugs to lowercase" do
    workspace = Workspace.new(name: "Test", slug: "UPPER", owner: @owner)
    assert workspace.valid?, "Expected uppercase slug to be normalized and valid"
    assert_equal "upper", workspace.slug
  end

  test "normalizes slug to lowercase" do
    workspace = Workspace.new(name: "Test", slug: "  my-slug  ", owner: @owner)
    assert_equal "my-slug", workspace.slug
  end

  test "belongs to owner" do
    workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
    assert_equal @owner, workspace.owner
  end

  test "has many memberships" do
    workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
    assert_respond_to workspace, :memberships
  end

  test "has many projects" do
    workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
    assert_respond_to workspace, :projects
  end

  test "has many api_keys" do
    workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
    assert_respond_to workspace, :api_keys
  end

  test "default plan is starter" do
    workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
    assert_equal "starter", workspace.plan
  end

  test "destroys memberships on delete" do
    workspace = Workspace.create!(name: "Test", slug: "test", owner: @owner)
    Membership.create!(workspace: workspace, user: @owner, role: :owner)
    assert_difference "Membership.count", -1 do
      workspace.destroy
    end
  end
end
