require "test_helper"

class Billing::CheckPlanLimitsTest < ActiveSupport::TestCase
  test "starter plan allows sdk calls under limit" do
    workspace = workspaces(:demo)
    workspace.update!(plan: "starter")
    result = Billing::CheckPlanLimits.call(workspace: workspace, resource: :sdk_calls)
    assert result[:allowed]
    assert_equal 50_000, result[:limit]
  end

  test "pro plan allows unlimited projects" do
    workspace = workspaces(:demo)
    workspace.update!(plan: "pro")
    result = Billing::CheckPlanLimits.call(workspace: workspace, resource: :projects)
    assert result[:allowed]
  end

  test "free plan has low limits" do
    workspace = workspaces(:demo)
    workspace.update!(plan: "free")
    result = Billing::CheckPlanLimits.call(workspace: workspace, resource: :sdk_calls)
    assert_equal 1_000, result[:limit]
  end
end
