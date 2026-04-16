module Scoring
  class Evaluate
    def self.call(scorer:, prompt_content:, input_vars:, output:)
      case scorer.scorer_type
      when "llm_judge" then score_with_llm(scorer, prompt_content, input_vars, output)
      when "exact_match" then score_exact_match(scorer, output)
      when "regex" then score_regex(scorer, output)
      else [ nil, "unsupported scorer type: #{scorer.scorer_type}" ]
      end
    end

    def self.score_with_llm(scorer, prompt_content, input_vars, output)
      client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

      response = client.messages.create(
        model: scorer.model_hint || PromptVersion::DEFAULT_MODEL_HINT,
        max_tokens: 256,
        system_: scorer.content,
        messages: [
          {
            role: "user",
            content: "Prompt used:\n#{prompt_content}\n\nVariables provided:\n#{input_vars.to_json}\n\nOutput received:\n#{output}"
          }
        ]
      )

      text = response.content.first.text
      parsed = JSON.parse(text)
      [ parsed["score"].to_f.clamp(0.0, 1.0), parsed["rationale"].to_s ]
    rescue JSON::ParserError => e
      [ nil, "scoring_error: #{e.message}" ]
    end

    def self.score_exact_match(scorer, output)
      match = output.to_s.strip == scorer.content.to_s.strip
      [ match ? 1.0 : 0.0, match ? "exact match" : "no match" ]
    end

    def self.score_regex(scorer, output)
      pattern = Regexp.new(scorer.content.to_s)
      match = pattern.match?(output.to_s)
      [ match ? 1.0 : 0.0, match ? "regex matched" : "regex did not match" ]
    rescue RegexpError => e
      [ nil, "invalid regex: #{e.message}" ]
    end

    private_class_method :score_with_llm, :score_exact_match, :score_regex
  end
end
