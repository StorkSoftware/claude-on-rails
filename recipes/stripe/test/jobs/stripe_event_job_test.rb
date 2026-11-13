require "test_helper"

class StripeEventJobTest < ActiveJob::TestCase
  test "processes the event" do
    event = StripeEvent.create!(stripe_id: "evt_test", event_type: "customer.created", payload: {})

    StripeEventJob.perform_now(event)

    assert event.reload.processed_at
  end
end
