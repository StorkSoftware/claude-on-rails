# Keys come from credentials (stripe.secret_key, stripe.webhook_secret);
# config/environments/test.rb sets fake ones. See "Stripe" in CLAUDE.md.
stripe = Rails.configuration.x.stripe
stripe.secret_key ||= Rails.application.credentials.dig(:stripe, :secret_key)
stripe.webhook_secret ||= Rails.application.credentials.dig(:stripe, :webhook_secret)

# Production must not boot without payments. The Docker build precompiles
# assets without credentials (SECRET_KEY_BASE_DUMMY), so it is skipped there.
if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
  missing = %i[secret_key webhook_secret].select { |key| stripe[key].blank? }
  if missing.any?
    raise <<~MESSAGE
      Stripe is enabled but credentials are missing: #{missing.map { |key| "stripe.#{key}" }.join(", ")}.
      Add them with `bin/rails credentials:edit`:

        stripe:
          secret_key: sk_live_...
          webhook_secret: whsec_...
    MESSAGE
  end
end

Stripe.api_key = stripe.secret_key
