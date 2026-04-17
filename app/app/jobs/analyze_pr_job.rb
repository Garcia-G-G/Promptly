class AnalyzePrJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound

  def perform(installation_id:, repo:, pr_number:, files:)
    installation = GithubInstallation.find(installation_id)
    comment = Github::AnalyzePr.call(
      installation: installation,
      repo: repo,
      pr_number: pr_number,
      files: files
    )

    return unless comment

    client = Octokit::Client.new(access_token: installation.access_token_ciphertext)
    client.add_comment(repo, pr_number, comment)
  rescue Octokit::Error => e
    Rails.logger.error("[GitHub] PR comment failed: #{e.message}")
  end
end
