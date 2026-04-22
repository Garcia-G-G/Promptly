require "test_helper"

module Web
  class DashboardStubsTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:owner)
      @workspace = workspaces(:demo)
      sign_in @user
    end

    test "experiments index renders" do
      get workspace_web_experiments_path(@workspace.slug)
      assert_response :success
      assert_select "h1", "Experiments"
    end

    test "logs index renders" do
      get workspace_web_logs_path(@workspace.slug)
      assert_response :success
      assert_select "h1", "Logs"
    end

    test "datasets index renders" do
      get workspace_web_datasets_path(@workspace.slug)
      assert_response :success
      assert_select "h1", "Datasets"
    end

    test "scorers index renders" do
      get workspace_web_scorers_path(@workspace.slug)
      assert_response :success
      assert_select "h1", "Scorers"
    end

    test "eval_runs index renders" do
      get workspace_web_eval_runs_path(@workspace.slug)
      assert_response :success
      assert_select "h1", "Eval Runs"
    end

    test "settings show renders" do
      get workspace_web_settings_path(@workspace.slug)
      assert_response :success
      assert_select ".settings-tabs"
      assert_select "h2", /Workspace settings/i
    end
  end
end
