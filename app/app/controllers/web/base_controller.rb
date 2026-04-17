module Web
  class BaseController < ApplicationController
    before_action :set_workspace

    private

    def set_workspace
      @workspace = current_workspace
    end
  end
end
