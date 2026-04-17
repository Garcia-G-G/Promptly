# frozen_string_literal: true

module Promptly
  class Configuration
    attr_accessor :api_key, :project, :environment, :base_url, :timeout, :otel_enabled, :logger

    def initialize
      @api_key      = ENV["PROMPTLY_KEY"]
      @project      = ENV["PROMPTLY_PROJECT"]
      @environment  = (ENV["PROMPTLY_ENV"] || "dev").to_sym
      @base_url     = ENV["PROMPTLY_URL"] || "https://api.promptly.dev"
      @timeout      = 5
      @otel_enabled = false
      @logger       = nil
    end

    def validate!
      raise Promptly::ConfigurationError, "api_key is required" if api_key.nil? || api_key.empty?
      raise Promptly::ConfigurationError, "project is required" if project.nil? || project.empty?
    end
  end
end
