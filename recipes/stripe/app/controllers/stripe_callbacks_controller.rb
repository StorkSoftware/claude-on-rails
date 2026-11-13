# Stripe's webhook endpoint. ActionController::API, because Stripe is not a
# browser: no session, CSRF token or allow_browser. The signature is the check.
class StripeCallbacksController < ActionController::API
  def create
    event = Stripe::Webhook.construct_event(request.raw_post, request.headers["Stripe-Signature"], webhook_secret)
    stripe_event = StripeEvent.create!(stripe_id: event.id, event_type: event.type, payload: JSON.parse(request.raw_post))
    StripeEventJob.perform_later(stripe_event)
    head :ok
  rescue ActiveRecord::RecordNotUnique
    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  end

  private
    def webhook_secret
      Rails.configuration.x.stripe.webhook_secret.presence or
        raise "stripe.webhook_secret is not set. Add it with `bin/rails credentials:edit`."
    end
end
