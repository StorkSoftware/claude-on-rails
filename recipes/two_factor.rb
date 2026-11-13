# TOTP two-factor authentication on top of the authentication generator:
# enrolment with a QR code, and a code challenge between password sign-in and
# the session cookie. Documented in the "Two-Factor Authentication" section of
# rails/CLAUDE.md.tt.
#
# New files (controllers, concern, helper, views, controller tests) live in
# recipes/two_factor/ and are copied as they are. This file only patches the
# files the authentication and home recipes generated.
require "securerandom"

gem "rotp"
gem "rqrcode"

after_bundle do
  generate "migration", "AddOtpSecretToUsers", "otp_secret:string"
  rails_command "db:migrate"

  # `encrypts :otp_secret` needs Active Record encryption keys: separate ones
  # per environment, and fixed ones for tests, which have no credentials.
  %w[development production].each do |environment|
    append_credentials environment, <<~YAML

      active_record_encryption:
        primary_key: #{SecureRandom.alphanumeric(32)}
        deterministic_key: #{SecureRandom.alphanumeric(32)}
        key_derivation_salt: #{SecureRandom.alphanumeric(32)}
    YAML
  end

  # `environment` inserts at the top of the block, so these land in reverse.
  environment 'config.active_record.encryption.key_derivation_salt = "test-key-derivation-salt"', env: "test"
  environment 'config.active_record.encryption.deterministic_key = "test-deterministic-key"', env: "test"
  environment 'config.active_record.encryption.primary_key = "test-primary-key"', env: "test"

  directory "recipes/two_factor", "."

  inject_into_file "app/models/user.rb", after: "normalizes :email_address, with: ->(e) { e.strip.downcase }\n" do
    <<-RUBY

  encrypts :otp_secret

  def self.generate_otp_secret
    ROTP::Base32.random
  end

  def self.otp_code_valid?(secret, code)
    ROTP::TOTP.new(secret).verify(code.to_s.gsub(/\\s/, ""), drift_behind: 15).present?
  end

  def two_factor_enabled?
    otp_secret.present?
  end

  def verify_otp(code)
    two_factor_enabled? && self.class.otp_code_valid?(otp_secret, code)
  end

  def enable_two_factor(secret, code)
    self.class.otp_code_valid?(secret, code) && update(otp_secret: secret)
  end

  def otp_provisioning_uri(secret)
    ROTP::TOTP.new(secret, issuer: #{project_name.inspect}).provisioning_uri(email_address)
  end
    RUBY
  end

  inject_into_file "app/controllers/sessions_controller.rb", after: "class SessionsController < ApplicationController\n" do
    "  include TwoFactorChallenge\n\n"
  end

  gsub_file "app/controllers/sessions_controller.rb", /^      start_new_session_for user\n      redirect_to after_authentication_url\n/ do
    <<-RUBY
      if user.two_factor_enabled?
        start_two_factor_challenge_for user
        redirect_to new_two_factor_challenge_path
      else
        start_new_session_for user
        redirect_to after_authentication_url
      end
    RUBY
  end

  inject_into_file "app/views/home/index.html.erb", before: %r{</div>\s*\z} do
    <<~ERB.gsub(/^(?!$)/, "  ")

      <% if notice = flash[:notice] %>
        <div id="notice" class="mt-6 rounded-md bg-green-50 p-4 dark:bg-green-500/10 dark:outline dark:outline-green-500/20">
          <div class="flex">
            <div class="shrink-0"><%= lucide_icon "circle-check", class: "size-5 text-green-400", "aria-hidden": "true" %></div>
            <p class="ml-3 text-sm font-medium text-green-800 dark:text-green-200"><%= notice %></p>
          </div>
        </div>
      <% end %>

      <% unless Current.user.two_factor_enabled? %>
        <div class="mt-6 bg-white shadow-sm sm:rounded-lg dark:bg-gray-800/50 dark:shadow-none dark:outline dark:-outline-offset-1 dark:outline-white/10">
          <div class="px-4 py-5 sm:p-6">
            <h2 class="text-base font-semibold text-gray-900 dark:text-white"><%= t(".two_factor_heading") %></h2>
            <div class="mt-2 sm:flex sm:items-start sm:justify-between">
              <p class="max-w-xl text-sm text-gray-500 dark:text-gray-400"><%= t(".two_factor_body") %></p>
              <div class="mt-5 sm:mt-0 sm:ml-6 sm:flex sm:shrink-0 sm:items-center">
                <%= link_to t(".set_up_two_factor"), new_two_factor_setup_path, class: "inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-xs hover:bg-indigo-500 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600 dark:bg-indigo-500 dark:shadow-none dark:hover:bg-indigo-400 dark:focus-visible:outline-indigo-500" %>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    ERB
  end

  route "resource :two_factor_setup, only: %i[ new create ]"
  route "resource :two_factor_challenge, only: %i[ new create ]"

  inject_into_file "config/locales/en.yml", after: "  home:\n    index:\n" do
    <<-YAML
      two_factor_heading: "Two-factor authentication"
      two_factor_body: "Ask for a code from your authenticator app every time you sign in."
      set_up_two_factor: "Set up"
    YAML
  end

  append_to_file "config/locales/en.yml" do
    <<-YAML
  two_factor_challenges:
    new:
      heading: "Two-factor authentication"
      instructions: "Enter the 6-digit code from your authenticator app."
      code: "Code"
      submit: "Verify"
    create:
      invalid_code: "That code didn't work. Try again."
    expired: "Your sign-in timed out. Sign in again."
    rate_limited: "Try again later."
  two_factor_setups:
    new:
      heading: "Set up two-factor authentication"
      instructions: "Scan the QR code with your authenticator app, then enter the 6-digit code it shows."
      manual_entry: "Can't scan it? Enter this key instead."
      code: "Code"
      submit: "Turn on"
    create:
      enabled: "Two-factor authentication is on."
      invalid_code: "That code didn't work. Try again."
    already_enabled: "Two-factor authentication is already on."
    YAML
  end

  inject_into_file "test/models/user_test.rb", before: /^end\s*\z/ do
    <<-RUBY
  test "otp_secret is encrypted at rest" do
    user = users(:one)
    user.update!(otp_secret: User.generate_otp_secret)

    assert_not_equal user.otp_secret, user.ciphertext_for(:otp_secret)
  end

  test "verify_otp accepts the current code and rejects another" do
    user = users(:one)
    user.update!(otp_secret: User.generate_otp_secret)
    code = ROTP::TOTP.new(user.otp_secret).now

    assert user.verify_otp(code)
    assert_not user.verify_otp(code.succ)
  end

  test "verify_otp is false when 2FA is off" do
    assert_not users(:one).verify_otp("123456")
  end
    RUBY
  end

  commit "Add two-factor authentication"
end
