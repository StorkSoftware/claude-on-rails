class TwoFactorSetupsController < ApplicationController
  before_action :redirect_if_enabled

  def new
    @secret = session[:pending_otp_secret] ||= User.generate_otp_secret
    @provisioning_uri = Current.user.otp_provisioning_uri(@secret)
  end

  def create
    secret = session[:pending_otp_secret]

    if secret && Current.user.enable_two_factor(secret, params[:code])
      session.delete(:pending_otp_secret)
      redirect_to root_path, notice: t(".enabled")
    else
      redirect_to new_two_factor_setup_path, alert: t(".invalid_code")
    end
  end

  private
    def redirect_if_enabled
      redirect_to root_path, notice: t("two_factor_setups.already_enabled") if Current.user.two_factor_enabled?
    end
end
