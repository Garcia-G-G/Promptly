module PromptVariables
  # Matches `{name}` tokens, alphanumeric + underscore, must start with a
  # letter or underscore. Mirrors what the runtime interpolator accepts.
  PATTERN = /\{([a-z_][a-z0-9_]*)\}/i

  # Extracts the unique variable names from a prompt template and returns
  # them in the shape PromptVersions::Push expects.
  #   PromptVariables.extract("Hi {name}, you said {msg}.")
  #   #=> [{ "name" => "name" }, { "name" => "msg" }]
  def self.extract(content)
    content.to_s.scan(PATTERN).flatten.uniq.map { |name| { "name" => name } }
  end
end
