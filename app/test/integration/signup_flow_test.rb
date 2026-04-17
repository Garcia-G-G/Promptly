require "test_helper"

class SignupFlowTest < ActionDispatch::IntegrationTest
  test "signup, confirm, create workspace, see workspace dashboard" do
    # Sign up
    get new_user_registration_path
    assert_response :success

    post user_registration_path, params: {
      user: {
        email: "newuser@example.com",
        password: "securepassword123",
        password_confirmation: "securepassword123",
        name: "New User"
      }
    }
    assert_response :redirect

    # Confirm the user
    user = User.find_by(email: "newuser@example.com")
    assert user.present?
    user.confirm

    # Sign in
    post user_session_path, params: {
      user: {
        email: "newuser@example.com",
        password: "securepassword123"
      }
    }
    assert_response :redirect

    # Create a workspace
    post workspaces_path, params: {
      workspace: {
        name: "My Workspace",
        slug: "my-workspace"
      }
    }
    assert_response :redirect
    follow_redirect!

    # Should be on the workspace dashboard
    assert_response :success
    assert_select "h1", "Overview"
  end
end
