require "test_helper"

module Web
  class SettingsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:owner)
      @workspace = workspaces(:demo)
      sign_in @user
    end

    # ── General ──

    test "show renders general settings" do
      get workspace_web_settings_path(@workspace.slug)
      assert_response :success
      assert_select ".settings-tabs"
      assert_select "input[name='workspace[name]']"
    end

    test "update changes workspace name" do
      patch workspace_web_settings_path(@workspace.slug), params: {
        workspace: { name: "Renamed Workspace" }
      }
      assert_redirected_to workspace_web_settings_path(@workspace.slug)
      assert_equal "Renamed Workspace", @workspace.reload.name
    end

    test "update with blank name fails" do
      patch workspace_web_settings_path(@workspace.slug), params: {
        workspace: { name: "" }
      }
      assert_response :unprocessable_entity
    end

    # ── Team ──

    test "team lists members with role badges" do
      get team_workspace_web_settings_path(@workspace.slug)
      assert_response :success
      assert_select ".data-table"
      assert_select ".role-badge", minimum: 2
    end

    test "invite_member adds existing user to workspace" do
      other = User.create!(
        email: "extra-#{SecureRandom.hex(3)}@test.com",
        password: "password123456",
        name: "Extra Member",
        confirmed_at: Time.current
      )

      assert_difference -> { @workspace.memberships.count } do
        assert_enqueued_emails 1 do
          post invite_member_workspace_web_settings_path(@workspace.slug), params: {
            email: other.email, role: "developer"
          }
        end
      end
      assert_redirected_to team_workspace_web_settings_path(@workspace.slug)
    ensure
      other&.destroy
    end

    test "invite_member fails for unknown email" do
      post invite_member_workspace_web_settings_path(@workspace.slug), params: {
        email: "nobody-#{SecureRandom.hex(3)}@example.com", role: "developer"
      }
      assert_redirected_to team_workspace_web_settings_path(@workspace.slug)
      follow_redirect!
      assert_match(/No user found/i, flash[:alert])
    end

    test "update_role changes member role" do
      membership = memberships(:dev_demo)
      patch update_member_role_workspace_web_settings_path(@workspace.slug, membership.id), params: {
        role: "admin"
      }
      assert_redirected_to team_workspace_web_settings_path(@workspace.slug)
      assert_equal "admin", membership.reload.role
    end

    test "update_role refuses to change owner" do
      owner_membership = memberships(:owner_demo)
      patch update_member_role_workspace_web_settings_path(@workspace.slug, owner_membership.id), params: {
        role: "admin"
      }
      assert_redirected_to team_workspace_web_settings_path(@workspace.slug)
      assert_equal "owner", owner_membership.reload.role
    end

    test "remove_member deletes non-owner membership" do
      extra_user = User.create!(
        email: "removeme-#{SecureRandom.hex(3)}@test.com",
        password: "password123456",
        name: "Removable",
        confirmed_at: Time.current
      )
      membership = @workspace.memberships.create!(user: extra_user, role: "developer")

      assert_difference -> { @workspace.memberships.count }, -1 do
        delete remove_member_workspace_web_settings_path(@workspace.slug, membership.id)
      end
      assert_redirected_to team_workspace_web_settings_path(@workspace.slug)
    ensure
      extra_user&.destroy
    end

    test "remove_member refuses to remove owner" do
      owner_membership = memberships(:owner_demo)
      assert_no_difference -> { @workspace.memberships.count } do
        delete remove_member_workspace_web_settings_path(@workspace.slug, owner_membership.id)
      end
    end

    # ── API Keys ──

    test "api_keys lists keys" do
      get api_keys_workspace_web_settings_path(@workspace.slug)
      assert_response :success
      assert_select ".data-table"
    end

    test "create_api_key via HTML sets flash raw key and redirects" do
      assert_difference -> { @workspace.api_keys.count } do
        post create_api_key_workspace_web_settings_path(@workspace.slug), params: { name: "HTML key" }
      end
      assert_redirected_to api_keys_workspace_web_settings_path(@workspace.slug)
      assert flash[:new_raw_key].present?
      assert flash[:new_raw_key].start_with?("pk_")
    end

    test "create_api_key via turbo stream renders stream" do
      post create_api_key_workspace_web_settings_path(@workspace.slug),
        params: { name: "Turbo key" },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
      assert_response :success
      assert_match(/turbo-stream/, response.body)
    end

    test "revoke_api_key marks key revoked" do
      key = @workspace.api_keys.create!(name: "Revokable")
      refute key.revoked?

      delete revoke_api_key_workspace_web_settings_path(@workspace.slug, key.id)
      assert key.reload.revoked?
    end

    test "revoke_api_key via turbo stream renders stream" do
      key = @workspace.api_keys.create!(name: "Turbo revoke")
      delete revoke_api_key_workspace_web_settings_path(@workspace.slug, key.id),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
      assert_response :success
      assert_match(/turbo-stream/, response.body)
      assert key.reload.revoked?
    end

    test "revoke already-revoked key surfaces alert" do
      key = api_keys(:revoked_key)
      delete revoke_api_key_workspace_web_settings_path(@workspace.slug, key.id)
      assert_redirected_to api_keys_workspace_web_settings_path(@workspace.slug)
      follow_redirect!
      assert_match(/already revoked/i, flash[:alert])
    end

    # ── Billing ──

    test "billing renders not-configured placeholder when Stripe is off" do
      original = ENV["STRIPE_SECRET_KEY"]
      ENV["STRIPE_SECRET_KEY"] = nil
      @workspace.update_column(:stripe_customer_id, nil)

      get billing_workspace_web_settings_path(@workspace.slug)
      assert_response :success
      assert_select "h2", text: /Billing not configured/i
      assert_select ".usage-meter__track"
    ensure
      ENV["STRIPE_SECRET_KEY"] = original
    end
  end
end
