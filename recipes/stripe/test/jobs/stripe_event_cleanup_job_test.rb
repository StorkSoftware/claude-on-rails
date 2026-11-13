require "test_helper"

class StripeEventCleanupJobTest < ActiveJob::TestCase
  test "deletes processed events older than the retention period only" do
    old_processed = create_event("evt_old", processed_at: StripeEvent::RETAIN_FOR.ago - 1.day)
    recent_processed = create_event("evt_recent", processed_at: 1.day.ago)
    old_unprocessed = create_event("evt_failed", processed_at: nil, created_at: StripeEvent::RETAIN_FOR.ago - 1.day)

    StripeEventCleanupJob.perform_now

    assert_not StripeEvent.exists?(old_processed.id)
    assert StripeEvent.exists?(recent_processed.id)
    assert StripeEvent.exists?(old_unprocessed.id)
  end

  private
    def create_event(stripe_id, **attributes)
      StripeEvent.create!(stripe_id:, event_type: "customer.created", payload: {}, **attributes)
    end
end
