module Github
  class AnalyzePr
    PROMPT_FILE_PATTERNS = [
      /prompts?\//i,
      /\.prompt\.(yml|yaml|json|txt|md)$/i,
      /prompt.*\.rb$/i
    ].freeze

    def self.call(installation:, repo:, pr_number:, files:)
      new(installation, repo, pr_number, files).call
    end

    def initialize(installation, repo, pr_number, files)
      @installation = installation
      @repo = repo
      @pr_number = pr_number
      @files = files
    end

    def call
      prompt_files = @files.select { |f| prompt_related?(f[:filename]) }
      return nil if prompt_files.empty?

      affected_slugs = extract_prompt_slugs(prompt_files)
      workspace = @installation.workspace

      experiments = Experiment.joins(prompt: { project: :workspace })
        .where(workspaces: { id: workspace.id })
        .where(status: :running)
        .where(prompts: { slug: affected_slugs })

      build_comment(prompt_files, affected_slugs, experiments)
    end

    private

    def prompt_related?(filename)
      PROMPT_FILE_PATTERNS.any? { |pattern| filename.match?(pattern) }
    end

    def extract_prompt_slugs(files)
      files.filter_map { |f|
        match = f[:filename].match(/prompts?\/([a-z0-9_-]+)/i)
        match ? match[1] : nil
      }.uniq
    end

    def build_comment(files, slugs, experiments)
      lines = []
      lines << "## Promptly - Prompt Changes Detected"
      lines << ""
      lines << "This PR modifies **#{files.size}** prompt-related file(s)."
      lines << ""
      lines << "### Files"
      files.each do |f|
        lines << "- `#{f[:filename]}` (+#{f[:additions] || 0}/-#{f[:deletions] || 0})"
      end

      if experiments.any?
        lines << ""
        lines << "### Active Experiments"
        lines << ""
        lines << "These prompts have running experiments:"
        lines << ""
        experiments.each do |exp|
          lines << "- **#{exp.name}** on `#{exp.prompt.slug}` (#{exp.traffic_split}% split)"
        end
      end

      lines << ""
      lines << "---"
      lines << "*Posted by [Promptly](https://promptly.dev)*"
      lines.join("\n")
    end
  end
end
