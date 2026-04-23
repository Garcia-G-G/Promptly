# frozen_string_literal: true

# OpenAI client is instantiated per-use:
#   OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
#
# No global configuration is needed for the ruby-openai gem; every
# service/job that calls out to OpenAI builds a short-lived client.
