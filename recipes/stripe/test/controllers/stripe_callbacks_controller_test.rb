require "test_helper"

class StripeCallbacksControllerTest < ActionDispatch::IntegrationTest
  test "a signed event is stored and queued" do
    assert_enqueued_with(job: StripeEventJob) do
      post_event event_payload
    end

    assert_response :ok
    assert_equal "checkout.session.completed", StripeEvent.find_by!(stripe_id: "evt_test").event_type
  end

  test "a repeated delivery is stored and queued once" do
    payload = event_payload
    post_event payload

    assert_no_difference "StripeEvent.count" do
      assert_no_enqueued_jobs { post_event payload }
    end
    assert_response :ok
  end

  test "a bad signature is rejected" do
    post_event event_payload, secret: "whsec_wrong"

    assert_response :bad_request
    assert_equal 0, StripeEvent.count
  end

  test "a missing signature is rejected" do
    post stripe_callback_path, params: event_payload, headers: { "Content-Type" => "application/json" }

    assert_response :bad_request
  end

  test "a signed payload that is not JSON is rejected" do
    post_event "{"

    assert_response :bad_request
  end

  private
    def event_payload
      { id: "evt_test", object: "event", type: "checkout.session.completed", data: { object: { id: "cs_test" } } }.to_json
    end

    def post_event(payload, secret: Rails.configuration.x.stripe.webhook_secret)
      timestamp = Time.current
      signature = Stripe::Webhook::Signature.compute_signature(timestamp, payload, secret)
      header = Stripe::Webhook::Signature.generate_header(timestamp, signature)
      post stripe_callback_path, params: payload, headers: { "Stripe-Signature" => header, "Content-Type" => "application/json" }
    end
end
