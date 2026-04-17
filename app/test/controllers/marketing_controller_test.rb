require "test_helper"

class MarketingControllerTest < ActionDispatch::IntegrationTest
  test "landing page renders for unauthenticated users" do
    get root_path
    assert_response :success
    assert_select "h1"
    assert_select ".nav"
    assert_select ".terminal"
    assert_select ".fcard", minimum: 3
    assert_select ".pcard", minimum: 2
  end
end
