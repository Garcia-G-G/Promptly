module Web
  class SettingsController < Web::BaseController
    ROLE_ORDER_SQL = "CASE role " \
      "WHEN 'owner' THEN 0 " \
      "WHEN 'admin' THEN 1 " \
      "WHEN 'developer' THEN 2 " \
      "WHEN 'viewer' THEN 3 END".freeze

    def show
      # General settings page — @workspace set by Web::BaseController.
    end

    def update
      if @workspace.update(workspace_params)
        redirect_to workspace_web_settings_path(@workspace.slug), notice: "Workspace updated."
      else
        flash.now[:alert] = @workspace.errors.full_messages.to_sentence
        render :show, status: :unprocessable_entity
      end
    end

    def team
      @memberships = @workspace.memberships
        .includes(:user)
        .order(Arel.sql(ROLE_ORDER_SQL))
        .order(:created_at)
    end

    def invite_member
      email = params[:email].to_s.strip.downcase
      user = User.find_by(email: email)

      if user.nil?
        redirect_to team_workspace_web_settings_path(@workspace.slug),
          alert: "No user found with that email address. They must sign up first."
        return
      end

      membership = @workspace.memberships.build(user: user, role: params[:role].presence || "developer")
      if membership.save
        MemberInvitationMailer.invite(membership).deliver_later
        redirect_to team_workspace_web_settings_path(@workspace.slug),
          notice: "#{user.name.presence || user.email} added to the workspace."
      else
        redirect_to team_workspace_web_settings_path(@workspace.slug),
          alert: membership.errors.full_messages.to_sentence
      end
    end

    def update_role
      membership = @workspace.memberships.find(params[:id])

      if membership.owner?
        redirect_to team_workspace_web_settings_path(@workspace.slug),
          alert: "Cannot change the owner's role."
        return
      end

      if membership.update(role: params[:role])
        redirect_to team_workspace_web_settings_path(@workspace.slug),
          notice: "Role updated to #{params[:role]}."
      else
        redirect_to team_workspace_web_settings_path(@workspace.slug),
          alert: membership.errors.full_messages.to_sentence
      end
    end

    def remove_member
      membership = @workspace.memberships.find(params[:id])

      if membership.owner?
        redirect_to team_workspace_web_settings_path(@workspace.slug),
          alert: "Cannot remove the workspace owner."
        return
      end

      if membership.user_id == current_user.id
        redirect_to team_workspace_web_settings_path(@workspace.slug),
          alert: "Cannot remove yourself from the workspace."
        return
      end

      removed_name = membership.user.name.presence || membership.user.email
      membership.destroy!
      redirect_to team_workspace_web_settings_path(@workspace.slug),
        notice: "#{removed_name} removed from workspace."
    end

    def api_keys
      @api_keys = @workspace.api_keys
        .order(Arel.sql("CASE WHEN revoked_at IS NULL THEN 0 ELSE 1 END"))
        .order(created_at: :desc)
      @new_raw_key = flash[:new_raw_key]
    end

    def create_api_key
      @api_key = @workspace.api_keys.build(name: params[:name])

      if @api_key.save
        respond_to do |format|
          format.turbo_stream
          format.html do
            flash[:new_raw_key] = @api_key.raw_key
            redirect_to api_keys_workspace_web_settings_path(@workspace.slug),
              notice: "API key '#{@api_key.name}' created."
          end
        end
      else
        redirect_to api_keys_workspace_web_settings_path(@workspace.slug),
          alert: @api_key.errors.full_messages.to_sentence
      end
    end

    def revoke_api_key
      @api_key = @workspace.api_keys.find(params[:id])

      if @api_key.revoked?
        redirect_to api_keys_workspace_web_settings_path(@workspace.slug),
          alert: "Key is already revoked."
        return
      end

      @api_key.revoke!

      respond_to do |format|
        format.turbo_stream
        format.html do
          redirect_to api_keys_workspace_web_settings_path(@workspace.slug),
            notice: "API key '#{@api_key.name}' has been revoked."
        end
      end
    end

    def billing
      @stripe_configured = ENV["STRIPE_SECRET_KEY"].present? && @workspace.stripe_customer_id.present?
      @plan_name = (@workspace.plan.presence || "free").titleize
      @billing_period_start = billing_period_start
      @billing_period_end = @billing_period_start.next_month - 1.day
      @usage_meters = build_usage_meters
      @portal_url = @stripe_configured ? stripe_portal_url : nil
      @invoices = @stripe_configured ? stripe_invoices : []
    end

    private

    def workspace_params
      params.require(:workspace).permit(:name)
    end

    def billing_period_start
      today = Date.current
      anchor = @workspace.created_at&.day || 1
      day = [ anchor, today.end_of_month.day ].min
      start = Date.new(today.year, today.month, day)
      start > today ? start.prev_month : start
    end

    def build_usage_meters
      [
        [ "SDK Calls",          :sdk_calls ],
        [ "Projects",           :projects ],
        [ "Active Experiments", :experiments ],
        [ "Eval Runs",          :eval_runs ]
      ].map do |label, resource|
        result = Billing::CheckPlanLimits.call(workspace: @workspace, resource: resource)
        {
          label: label,
          current: result[:current] || 0,
          limit: result[:limit] || Float::INFINITY
        }
      end
    end

    def stripe_portal_url
      session = Stripe::BillingPortal::Session.create(
        customer: @workspace.stripe_customer_id,
        return_url: billing_workspace_web_settings_url(@workspace.slug)
      )
      session.url
    rescue Stripe::StripeError => e
      Rails.logger.error("[Settings] Stripe portal session failed: #{e.message}")
      nil
    end

    def stripe_invoices
      Stripe::Invoice.list(customer: @workspace.stripe_customer_id, limit: 12).data
    rescue Stripe::StripeError => e
      Rails.logger.error("[Settings] Invoice fetch failed: #{e.message}")
      []
    end
  end
end
