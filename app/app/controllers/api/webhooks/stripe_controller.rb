module Api
  module Webhooks
    class StripeController < ActionController::API
      def create
        payload = request.body.read
        sig = request.env["HTTP_STRIPE_SIGNATURE"]

        begin
          event = Stripe::Webhook.construct_event(payload, sig, ENV["STRIPE_WEBHOOK_SECRET"])
        rescue JSON::ParserError, Stripe::SignatureVerificationError => e
          render json: { error: e.message }, status: :bad_request and return
        end

        case event.type
        when "customer.subscription.created", "customer.subscription.updated"
          handle_subscription(event.data.object)
        when "customer.subscription.deleted"
          handle_cancellation(event.data.object)
        end

        render json: { received: true }
      end

      private

      def handle_subscription(subscription)
        workspace = Workspace.find_by(stripe_customer_id: subscription.customer)
        return unless workspace

        plan = subscription.items.data.first&.price&.lookup_key
        workspace.update!(plan: plan) if plan.present?
      end

      def handle_cancellation(subscription)
        workspace = Workspace.find_by(stripe_customer_id: subscription.customer)
        workspace&.update!(plan: "free")
      end
    end
  end
end
