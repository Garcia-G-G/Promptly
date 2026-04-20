require "test_helper"

class DeviseViewsTest < ActionDispatch::IntegrationTest
  test "login page renders with Promptly styling" do
    get new_user_session_path
    assert_response :success
    assert_select ".auth-card"
    assert_select "input[type=?]", "email"
    assert_select "input[type=?]", "password"
    assert_select ".auth-btn"
    assert_select "h1", /Welcome back/
  end

  test "registration page renders with Promptly styling" do
    get new_user_registration_path
    assert_response :success
    assert_select ".auth-card"
    assert_select "input[type=?]", "email"
    assert_select "input[type=?]", "password"
    assert_select "input#user_name"
    assert_select ".auth-btn"
    assert_select "h1", /Create your account/
  end
end
