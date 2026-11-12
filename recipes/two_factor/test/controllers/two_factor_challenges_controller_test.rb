require "test_helper"

class TwoFactorChallengesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @user.update!(otp_secret: User.generate_otp_secret)
  end

  test "signing in with 2FA asks for a code before starting a session" do
    sign_in_with_password

    assert_redirected_to new_two_factor_challenge_path
    assert_nil cookies[:session_id]
  end

  test "a valid code starts the session" do
    sign_in_with_password
    post two_factor_challenge_path, params: { code: current_code }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "an invalid code does not start a session" do
    sign_in_with_password
    post two_factor_challenge_path, params: { code: current_code.succ }

    assert_redirected_to new_two_factor_challenge_path
    assert_nil cookies[:session_id]
  end

  test "the challenge needs a password sign-in first" do
    get new_two_factor_challenge_path

    assert_redirected_to new_session_path
  end

  test "the challenge expires" do
    sign_in_with_password

    travel TwoFactorChallenge::PENDING_FOR + 1.second do
      post two_factor_challenge_path, params: { code: current_code }
    end

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  private
    def sign_in_with_password
      post session_path, params: { email_address: @user.email_address, password: "password" }
    end

    def current_code
      ROTP::TOTP.new(@user.otp_secret).now
    end
end
