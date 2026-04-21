module Web
  class SettingsController < Web::BaseController
    def show
      @memberships = @workspace.memberships.includes(:user).order(:created_at)
      @api_keys = @workspace.api_keys.order(:created_at)
    end
  end
end
