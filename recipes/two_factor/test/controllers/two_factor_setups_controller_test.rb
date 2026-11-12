require "test_helper"

class TwoFactorSetupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "new shows a QR code and the key" do
    get new_two_factor_setup_path

    assert_response :success
    assert_select "svg"
    assert_select "#otp_secret", text: session[:pending_otp_secret]
  end

  test "a valid code turns on 2FA" do
    get new_two_factor_setup_path
    secret = session[:pending_otp_secret]
    post two_factor_setup_path, params: { code: ROTP::TOTP.new(secret).now }

    assert_redirected_to root_path
    assert_equal secret, @user.reload.otp_secret
  end

  test "an invalid code leaves 2FA off" do
    get new_two_factor_setup_path
    code = ROTP::TOTP.new(session[:pending_otp_secret]).now
    post two_factor_setup_path, params: { code: code.succ }

    assert_redirected_to new_two_factor_setup_path
    assert_nil @user.reload.otp_secret
  end

  test "setup redirects home when 2FA is already on" do
    @user.update!(otp_secret: User.generate_otp_secret)
    get new_two_factor_setup_path

    assert_redirected_to root_path
  end

  test "setup requires sign-in" do
    sign_out
    get new_two_factor_setup_path

    assert_redirected_to new_session_path
  end
end
