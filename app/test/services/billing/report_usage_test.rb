require "test_helper"

class Billing::ReportUsageTest < ActiveSupport::TestCase
  test "skips when no stripe customer id" do
    workspace = workspaces(:demo)
    workspace.update!(stripe_customer_id: nil)
    assert_nothing_raised do
      Billing::ReportUsage.call(workspace: workspace)
    end
  end

  test "skips when no stripe secret key" do
    workspace = workspaces(:demo)
    workspace.update!(stripe_customer_id: "cus_test")
    original = ENV["STRIPE_SECRET_KEY"]
    ENV["STRIPE_SECRET_KEY"] = nil
    begin
      assert_nothing_raised do
        Billing::ReportUsage.call(workspace: workspace)
      end
    ensure
      ENV["STRIPE_SECRET_KEY"] = original
    end
  end
end
