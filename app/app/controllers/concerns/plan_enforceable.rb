module PlanEnforceable
  extend ActiveSupport::Concern

  private

  def enforce_sdk_call_limit!
    result = Billing::CheckPlanLimits.call(workspace: current_workspace, resource: :sdk_calls)

    unless result[:allowed]
      render json: {
        error: "plan_limit_reached",
        message: "SDK call limit reached for your plan",
        limit: result[:limit],
        current: result[:current],
        plan: current_workspace.plan
      }, status: :too_many_requests
    end
  end

  def report_sdk_usage!
    Billing::ReportUsage.call(workspace: current_workspace)
  end
end
