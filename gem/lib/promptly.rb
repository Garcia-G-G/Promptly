# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require "securerandom"

require_relative "promptly/version"
require_relative "promptly/configuration"
require_relative "promptly/errors"
require_relative "promptly/client"
require_relative "promptly/prompt"
require_relative "promptly/instrumentation"

module Promptly
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset!
      @configuration = Configuration.new
      @client = nil
    end

    def get(slug, vars: {}, env: nil, request_id: nil)
      configuration.validate!
      request_id ||= SecureRandom.uuid

      payload = {
        environment: (env || configuration.environment).to_s,
        request_id: request_id,
        variables: vars
      }

      response = client.post("/api/v1/prompts/#{slug}/resolve", payload)

      Prompt.new(
        slug: slug,
        content: response["content"],
        version: response["version_number"],
        version_id: response["version_id"],
        environment: response["environment"],
        experiment: response["experiment"],
        variant: response["variant"],
        model_hint: response["model_hint"],
        variables: vars,
        request_id: request_id
      )
    end

    def log(prompt_slug:, output:, request_id: nil, input_vars: {}, latency_ms: nil, tokens: {}, model_version: nil)
      configuration.validate!

      payload = {
        request_id: request_id || SecureRandom.uuid,
        output: output,
        input_vars: input_vars,
        latency_ms: latency_ms,
        tokens: tokens,
        model_version: model_version
      }.compact

      client.post("/api/v1/prompts/#{prompt_slug}/log", payload)
      true
    end

    def with(slug, request_id: nil, vars: {}, env: nil, &block)
      request_id ||= SecureRandom.uuid
      prompt = get(slug, vars: vars, env: env, request_id: request_id)

      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

      result = Instrumentation.wrap(slug, prompt, &block)

      latency_ms = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) - start_time

      output_text = extract_output(result)

      log(
        prompt_slug: slug,
        request_id: request_id,
        output: output_text,
        input_vars: vars,
        latency_ms: latency_ms
      )

      result
    end

    private

    def client
      @client ||= Client.new(configuration)
    end

    def extract_output(result)
      return result if result.is_a?(String)

      if result.respond_to?(:content) && result.content.is_a?(Array)
        text_blocks = result.content.select { |b| b.respond_to?(:text) }
        return text_blocks.map(&:text).join("\n") unless text_blocks.empty?
      end

      if result.respond_to?(:dig)
        choice_text = result.dig("choices", 0, "message", "content")
        return choice_text if choice_text
      end

      result.to_s
    end
  end
end
