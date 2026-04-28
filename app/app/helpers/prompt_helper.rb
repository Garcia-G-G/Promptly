module PromptHelper
  # Renders prompt content with `{variable}` tokens highlighted, while
  # HTML-escaping all surrounding user input. Prevents XSS when a prompt
  # version's content contains script or markup.
  VARIABLE_PATTERN = /\{(\w+)\}/

  def highlight_prompt_variables(content)
    return "".html_safe if content.blank?

    parts = []
    last_index = 0

    content.to_s.scan(VARIABLE_PATTERN) do |name|
      match = Regexp.last_match
      parts << ERB::Util.html_escape(content[last_index...match.begin(0)])
      parts << content_tag(
        :span,
        "{#{ERB::Util.html_escape(name.first)}}",
        class: "prompt-variable"
      )
      last_index = match.end(0)
    end

    parts << ERB::Util.html_escape(content[last_index..])
    safe_join(parts).html_safe
  end
end
