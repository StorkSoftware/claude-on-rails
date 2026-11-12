class TwoFactorChallengesController < ApplicationController
  include TwoFactorChallenge

  allow_unauthenticated_access
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: t("two_factor_challenges.rate_limited") }
  before_action :set_pending_user

  def new
  end

  def create
    if @user.verify_otp(params[:code])
      clear_two_factor_challenge
      start_new_session_for @user
      redirect_to after_authentication_url
    else
      redirect_to new_two_factor_challenge_path, alert: t(".invalid_code")
    end
  end

  private
    def set_pending_user
      @user = pending_two_factor_user
      return if @user

      clear_two_factor_challenge
      redirect_to new_session_path, alert: t("two_factor_challenges.expired")
    end
end
