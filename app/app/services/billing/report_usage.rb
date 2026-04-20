module Billing
  class ReportUsage
    def self.call(workspace:, event_name: "sdk_call", value: 1)
      return unless workspace.stripe_customer_id.present?
      return unless ENV["STRIPE_SECRET_KEY"].present?

      Stripe::Billing::MeterEvent.create({
        event_name: event_name,
        payload: {
          value: value.to_s,
          stripe_customer_id: workspace.stripe_customer_id
        },
        timestamp: Time.current.to_i
      })
    rescue Stripe::StripeError => e
      Rails.logger.error("[Billing] Usage report failed for workspace #{workspace.id}: #{e.message}")
    end
  end
end
