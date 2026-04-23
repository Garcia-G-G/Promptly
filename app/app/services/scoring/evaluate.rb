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
      client = OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))

      response = client.chat(
        parameters: {
          model: scorer.model_hint || PromptVersion::DEFAULT_MODEL_HINT,
          max_tokens: 256,
          messages: [
            { role: "system", content: scorer.content },
            {
              role: "user",
              content: "Prompt used:\n#{prompt_content}\n\nVariables provided:\n#{input_vars.to_json}\n\nOutput received:\n#{output}"
            }
          ],
          response_format: { type: "json_object" }
        }
      )

      text = response.dig("choices", 0, "message", "content")
      parsed = JSON.parse(text.to_s)
      [ parsed["score"].to_f.clamp(0.0, 1.0), parsed["rationale"].to_s ]
    rescue JSON::ParserError => e
      [ nil, "scoring_error: #{e.message}" ]
    end

    def self.score_exact_match(scorer, output)
      match = output.to_s.strip == scorer.content.to_s.strip
      [ match ? 1.0 : 0.0, match ? "exact match" : "no match" ]
    end

    MAX_REGEX_LENGTH = 500

    def self.score_regex(scorer, output)
      raw_pattern = scorer.content.to_s
      if raw_pattern.length > MAX_REGEX_LENGTH
        return [ nil, "regex too long (max #{MAX_REGEX_LENGTH} chars)" ]
      end

      pattern = Regexp.new(raw_pattern, timeout: 1.0)
      match = pattern.match?(output.to_s)
      [ match ? 1.0 : 0.0, match ? "regex matched" : "regex did not match" ]
    rescue Regexp::TimeoutError
      [ nil, "regex timed out (possible catastrophic backtracking)" ]
    rescue RegexpError => e
      [ nil, "invalid regex: #{e.message}" ]
    end

    private_class_method :score_with_llm, :score_exact_match, :score_regex
  end
end
