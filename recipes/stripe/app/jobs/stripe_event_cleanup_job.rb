class StripeEventCleanupJob < ApplicationJob
  def perform
    StripeEvent.processed_before(StripeEvent::RETAIN_FOR.ago).in_batches.delete_all
  end
end
