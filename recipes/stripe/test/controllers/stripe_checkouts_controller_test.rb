require "test_helper"
require "minitest/mock"

class StripeCheckoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "create sends the user to Stripe Checkout" do
    checkout = Stripe::Checkout::Session.construct_from(url: "https://checkout.stripe.com/c/pay/cs_test")
    params = nil
    create = ->(given, *) { params = given; checkout }

    Stripe::Checkout::Session.stub(:create, create) do
      post stripe_checkout_path
    end

    assert_redirected_to checkout.url
    assert_response :see_other
    assert_equal @user.id, params[:client_reference_id]
    assert_equal success_stripe_checkout_url, params[:success_url]
  end

  test "success shows the confirmation" do
    get success_stripe_checkout_path

    assert_response :success
    assert_select "h1"
  end

  test "checkout requires sign-in" do
    sign_out
    post stripe_checkout_path

    assert_redirected_to new_session_path
  end
end
