# frozen_string_literal: true

require_relative "lib/promptly/version"

Gem::Specification.new do |spec|
  spec.name          = "promptly"
  spec.version       = Promptly::VERSION
  spec.authors       = ["Promptly"]
  spec.email         = ["hello@promptly.dev"]

  spec.summary       = "Ruby SDK for Promptly — prompt version control & A/B testing"
  spec.description   = "Resolve versioned prompts, log outputs, and run A/B experiments with the Promptly platform."
  spec.homepage      = "https://github.com/promptly-dev/promptly-ruby"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata = {
    "homepage_uri" => "https://promptly.dev",
    "source_code_uri" => "https://github.com/promptly-dev/promptly-ruby",
    "changelog_uri" => "https://github.com/promptly-dev/promptly-ruby/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }

  spec.files         = Dir["lib/**/*.rb", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "opentelemetry-api", "~> 1.0"
  spec.add_development_dependency "opentelemetry-sdk", "~> 1.0"
end
