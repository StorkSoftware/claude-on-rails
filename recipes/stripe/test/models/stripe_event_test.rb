require "test_helper"

class StripeEventTest < ActiveSupport::TestCase
  test "process handles a completed checkout and marks the event processed" do
    event = create_event("checkout.session.completed", { "id" => "cs_test", "client_reference_id" => users(:one).id })

    event.process

    assert event.reload.processed_at
  end

  test "process marks event types it does not handle as processed" do
    event = create_event("customer.created", { "id" => "cus_test" })

    event.process

    assert event.reload.processed_at
  end

  test "a failed event stays unprocessed" do
    event = create_event("checkout.session.completed", { "id" => "cs_test", "client_reference_id" => 0 })

    assert_raises(ActiveRecord::RecordNotFound) { event.process }
    assert_nil event.reload.processed_at
  end

  private
    def create_event(type, object)
      StripeEvent.create!(stripe_id: "evt_#{type}", event_type: type, payload: { "type" => type, "data" => { "object" => object } })
    end
end
