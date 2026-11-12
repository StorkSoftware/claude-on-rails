# TOTP two-factor authentication on top of the authentication generator:
# enrolment with a QR code, and a code challenge between password sign-in and
# the session cookie. Documented in the "Two-Factor Authentication" section of
# rails/CLAUDE.md.tt.
#
# New files (controllers, concern, helper, views, controller tests) live in
# recipes/two_factor/ and are copied as they are. This file only patches the
# files the authentication and home recipes generated.
require "active_support/encrypted_configuration"
require "securerandom"

gem "rotp"
gem "rqrcode"

after_bundle do
  generate "migration", "AddOtpSecretToUsers", "otp_secret:string"
  rails_command "db:migrate"

  # `encrypts :otp_secret` needs Active Record encryption keys.
  credentials = ActiveSupport::EncryptedConfiguration.new(
    config_path: File.join(destination_root, "config/credentials.yml.enc"),
    key_path: File.join(destination_root, "config/master.key"),
    env_key: "RAILS_MASTER_KEY",
    raise_if_missing_key: true
  )
  credentials.write(credentials.read + <<~YAML)

    active_record_encryption:
      primary_key: #{SecureRandom.alphanumeric(32)}
      deterministic_key: #{SecureRandom.alphanumeric(32)}
      key_derivation_salt: #{SecureRandom.alphanumeric(32)}
  YAML

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

  inject_into_file "app/views/home/index.html.erb", after: "<div>\n" do
    <<~ERB.gsub(/^/, "  ")
      <% if notice = flash[:notice] %>
        <p class="py-2 px-3 bg-green-50 mb-5 text-green-500 font-medium rounded-lg inline-block" id="notice"><%= notice %></p>
      <% end %>
    ERB
  end

  inject_into_file "app/views/home/index.html.erb", before: %r{</div>\s*\z} do
    <<~ERB.gsub(/^/, "  ")
      <% unless Current.user.two_factor_enabled? %>
        <p class="mt-4"><%= link_to t(".set_up_two_factor"), new_two_factor_setup_path, class: "text-blue-600 underline hover:no-underline" %></p>
      <% end %>
    ERB
  end

  route "resource :two_factor_setup, only: %i[ new create ]"
  route "resource :two_factor_challenge, only: %i[ new create ]"

  append_to_file "config/locales/en.yml" do
    <<-YAML
  home:
    index:
      set_up_two_factor: "Set up two-factor authentication"
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
