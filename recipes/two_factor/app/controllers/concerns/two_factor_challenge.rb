module TwoFactorChallenge
  PENDING_FOR = 5.minutes

  private
    def start_two_factor_challenge_for(user)
      session[:two_factor_pending] = { "user_id" => user.id, "expires_at" => PENDING_FOR.from_now.to_i }
    end

    def pending_two_factor_user
      pending = session[:two_factor_pending]
      User.find_by(id: pending["user_id"]) if pending && pending["expires_at"].to_i > Time.current.to_i
    end

    def clear_two_factor_challenge
      session.delete(:two_factor_pending)
    end
end
