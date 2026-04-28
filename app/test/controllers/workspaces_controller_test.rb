require "test_helper"

class WorkspacesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:owner)
    @workspace = workspaces(:demo)
    sign_in @user
  end

  test "new renders the create form" do
    get new_workspace_path
    assert_response :success
    assert_select "form"
  end

  test "create persists workspace and owner membership" do
    name = "QA Workspace #{SecureRandom.hex(2)}"
    slug = "qa-#{SecureRandom.hex(3)}"

    assert_difference -> { Workspace.count } do
      assert_difference -> { Membership.count } do
        post workspaces_path, params: { workspace: { name: name, slug: slug } }
      end
    end

    created = Workspace.find_by!(slug: slug)
    assert_equal @user, created.owner
    assert created.memberships.exists?(user: @user, role: "owner")
    assert_redirected_to workspace_path(created.slug)
  end

  test "create with blank name re-renders the form" do
    post workspaces_path, params: { workspace: { name: "", slug: "blank-#{SecureRandom.hex(3)}" } }
    assert_response :unprocessable_entity
  end

  test "show loads overview stats and renders the dashboard" do
    get workspace_path(@workspace.slug)
    assert_response :success
    assert_select ".stat-grid"
    assert_select ".sidebar"
  end
end
