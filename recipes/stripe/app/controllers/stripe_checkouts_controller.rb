class StripeCheckoutsController < ApplicationController
  # The example item. Replace it with what the app sells; the amount is in cents.
  ITEM = { amount: 1000, currency: "eur" }.freeze

  def create
    checkout = Stripe::Checkout::Session.create(
      mode: "payment",
      line_items: [ {
        quantity: 1,
        price_data: { currency: ITEM[:currency], unit_amount: ITEM[:amount], product_data: { name: t(".item_name") } }
      } ],
      client_reference_id: Current.user.id,
      customer_email: Current.user.email_address,
      success_url: success_stripe_checkout_url,
      cancel_url: root_url
    )

    redirect_to checkout.url, allow_other_host: true, status: :see_other
  end

  def success
  end
end
