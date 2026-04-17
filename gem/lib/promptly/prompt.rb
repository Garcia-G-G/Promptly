# frozen_string_literal: true

module Promptly
  class Prompt
    attr_reader :slug, :content, :version, :version_id, :environment,
                :experiment, :variant, :model_hint, :variables, :request_id

    def initialize(slug:, content:, version:, version_id:, environment:, experiment:, variant:, model_hint:, variables:, request_id:)
      @slug        = slug
      @content     = content
      @version     = version
      @version_id  = version_id
      @environment = environment
      @experiment  = experiment
      @variant     = variant
      @model_hint  = model_hint
      @variables   = variables || {}
      @request_id  = request_id
    end

    def to_s
      result = content.dup
      variables.each do |key, value|
        result.gsub!("{#{key}}", value.to_s)
      end
      result
    end

    def experiment?
      !experiment.nil?
    end

    def to_h
      {
        slug: slug,
        content: content,
        version: version,
        version_id: version_id,
        environment: environment,
        experiment: experiment,
        variant: variant,
        model_hint: model_hint,
        variables: variables,
        request_id: request_id
      }
    end
  end
end
