require "test_helper"

class MarketingControllerTest < ActionDispatch::IntegrationTest
  test "landing page renders for unauthenticated users" do
    get root_path
    assert_response :success
    assert_select "h1", /Prompt management/
    assert_select "nav"
    assert_select ".hero"
    assert_select ".feature-section", minimum: 3
    assert_select ".pricing-card", 3
  end

  test "landing page redirects authenticated users to their first workspace" do
    sign_in users(:owner)
    get root_path
    assert_redirected_to workspace_path(users(:owner).workspaces.first.slug)
  end
end
