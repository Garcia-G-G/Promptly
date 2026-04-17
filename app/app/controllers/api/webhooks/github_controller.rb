module Api
  module Webhooks
    class GithubController < ActionController::API
      def create
        verify_signature!
        event = request.headers["X-GitHub-Event"]
        payload = JSON.parse(request.body.read)

        case event
        when "pull_request"
          handle_pull_request(payload) if %w[opened synchronize].include?(payload["action"])
        when "installation"
          handle_installation(payload)
        end

        render json: { received: true }
      end

      private

      def verify_signature!
        body = request.body.read
        request.body.rewind
        secret = ENV["GITHUB_WEBHOOK_SECRET"]
        return unless secret.present?

        signature = "sha256=" + OpenSSL::HMAC.hexdigest("SHA256", secret, body)
        unless Rack::Utils.secure_compare(signature, request.headers["X-Hub-Signature-256"].to_s)
          render json: { error: "Invalid signature" }, status: :unauthorized
        end
      end

      def handle_pull_request(payload)
        installation_id = payload.dig("installation", "id")
        installation = GithubInstallation.find_by(installation_id: installation_id)
        return unless installation

        repo = payload.dig("repository", "full_name")
        pr_number = payload.dig("pull_request", "number")
        files = (payload.dig("pull_request", "changed_files") || 0) > 0 ? extract_files(payload) : []

        AnalyzePrJob.perform_later(
          installation_id: installation.id,
          repo: repo,
          pr_number: pr_number,
          files: files
        )
      end

      def extract_files(payload)
        # PR webhook doesn't include file list — the job will fetch it
        # Pass empty array, the job should fetch files via API if needed
        []
      end

      def handle_installation(payload)
        case payload["action"]
        when "deleted"
          GithubInstallation.find_by(installation_id: payload["installation"]["id"])&.destroy
        end
      end
    end
  end
end
