# Every webhook event Stripe sends, stored once (unique stripe_id) and handled
# by StripeEventJob. processed_at stays blank when handling fails.
class StripeEvent < ApplicationRecord
  RETAIN_FOR = 90.days

  scope :processed_before, ->(time) { where(processed_at: ...time) }

  def process
    case event_type
    when "checkout.session.completed" then fulfil_checkout
    end

    update!(processed_at: Time.current)
  end

  private
    def stripe_object
      payload.dig("data", "object")
    end

    # Fulfil the order here: the user paid for StripeCheckoutsController::ITEM.
    def fulfil_checkout
      user = User.find(stripe_object["client_reference_id"])
      Rails.logger.info "Stripe checkout #{stripe_object["id"]} paid by user #{user.id}"
    end
end
