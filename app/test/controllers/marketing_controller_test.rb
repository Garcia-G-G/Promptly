require "test_helper"

class MarketingControllerTest < ActionDispatch::IntegrationTest
  test "landing page renders for unauthenticated users" do
    get root_path
    assert_response :success
    assert_select "h1", /Version control/
    assert_select ".landing-nav"
    assert_select ".code-window"
    assert_select ".feature-card", minimum: 6
    assert_select ".pricing-card", minimum: 2
  end
end
