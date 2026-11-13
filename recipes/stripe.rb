# Stripe Checkout (redirect to Stripe's hosted page) and a signed webhook
# endpoint at /stripe/callback that stores each event once and handles it in a
# job. Documented in the "Stripe" section of rails/CLAUDE.md.tt.
#
# New files live in recipes/stripe/ and are copied as they are. Applied after
# the csp recipe, because Checkout needs a form-action exception.
gem "stripe"

gem_group :test do
  # Minitest 6 moved `stub` out of minitest; the checkout test stubs Stripe's API.
  gem "minitest-mock"
end

after_bundle do
  generate "migration", "CreateStripeEvents", "stripe_id:string!:uniq", "event_type:string!", "payload:jsonb!", "processed_at:datetime:index"
  rails_command "db:migrate"

  directory "recipes/stripe", "."

  environment 'config.x.stripe.webhook_secret = "whsec_test"', env: "test"
  environment 'config.x.stripe.secret_key = "sk_test_fake"', env: "test"

  route <<~RUBY
    scope "stripe", as: "stripe" do
      post "callback", to: "stripe_callbacks#create"
      resource :checkout, only: :create, controller: "stripe_checkouts" do
        get :success
      end
    end
  RUBY

  # Checkout's POST redirects to Stripe, and form-action applies to redirects.
  gsub_file "config/initializers/content_security_policy.rb",
    /^(\s*policy\.form_action\s+:self)$/, '\1, "https://checkout.stripe.com"'

  append_to_file "config/recurring.yml", <<-YAML
  clean_up_stripe_events:
    class: StripeEventCleanupJob
    schedule: every day at 4am
  YAML

  inject_into_file "app/views/home/index.html.erb", before: %r{</div>\s*\z} do
    <<~ERB.gsub(/^(?!$)/, "  ")

      <div class="mt-6 bg-white shadow-sm sm:rounded-lg dark:bg-gray-800/50 dark:shadow-none dark:outline dark:-outline-offset-1 dark:outline-white/10">
        <div class="px-4 py-5 sm:p-6">
          <h2 class="text-base font-semibold text-gray-900 dark:text-white"><%= t("stripe_checkouts.panel.heading") %></h2>
          <div class="mt-2 sm:flex sm:items-start sm:justify-between">
            <p class="max-w-xl text-sm text-gray-500 dark:text-gray-400"><%= t("stripe_checkouts.panel.body") %></p>
            <div class="mt-5 sm:mt-0 sm:ml-6 sm:flex sm:shrink-0 sm:items-center">
              <%# Turbo submits with fetch, which cannot follow the redirect to Stripe. %>
              <%= button_to t("stripe_checkouts.panel.pay"), stripe_checkout_path, form: { data: { turbo: false } }, class: "inline-flex cursor-pointer items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-indigo-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 dark:bg-indigo-500 dark:shadow-none dark:hover:bg-indigo-400 dark:focus-visible:outline-indigo-500" %>
            </div>
          </div>
        </div>
      </div>
    ERB
  end

  append_to_file "config/locales/en.yml" do
    <<-YAML
  stripe_checkouts:
    panel:
      heading: "Payments"
      body: "Pay for the example item on Stripe's checkout page. Use a test card in test mode."
      pay: "Make a test payment"
    create:
      item_name: "Test item"
    success:
      heading: "Payment received"
      body: "Thanks! Your order is confirmed once Stripe tells us the payment went through."
      back: "Back to home"
    YAML
  end

  commit "Add Stripe Checkout and webhook callback"
end
