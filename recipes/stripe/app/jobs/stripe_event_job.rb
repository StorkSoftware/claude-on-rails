class StripeEventJob < ApplicationJob
  def perform(stripe_event)
    stripe_event.process
  end
end
