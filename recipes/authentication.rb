# Prepares the databases, runs the authentication generator and seeds a
# development user.
after_bundle do
  rails_command "db:prepare"

  generate "authentication"

  # Replaces the generator's sign-in and password views with Tailwind Plus
  # forms (labels, dark mode, copy in en.yml).
  directory "recipes/authentication", ".", force: true

  # Moves the generator's flash messages into en.yml. Lambdas and before_action
  # callbacks use absolute keys, since lazy lookup follows the action name.
  {
    "app/controllers/sessions_controller.rb" => {
      %(alert: "Try again later.") => %(alert: t("sessions.rate_limited")),
      %(alert: "Try another email address or password.") => %(alert: t(".invalid")),
    },
    "app/controllers/passwords_controller.rb" => {
      %(alert: "Try again later.") => %(alert: t("passwords.rate_limited")),
      %(notice: "Password reset instructions sent (if user with that email address exists).") => %(notice: t(".sent")),
      %(notice: "Password has been reset.") => %(notice: t(".reset")),
      %(alert: "Passwords did not match.") => %(alert: t(".mismatch")),
      %(alert: "Password reset link is invalid or has expired.") => %(alert: t("passwords.invalid_token")),
    },
  }.each do |path, replacements|
    replacements.each do |from, to|
      abort_template("#{path} no longer contains #{from}; update recipes/authentication.rb") unless File.read(File.join(destination_root, path)).include?(from)
      gsub_file path, from, to
    end
  end

  append_to_file "config/locales/en.yml", <<-YAML
  sessions:
    rate_limited: "Try again later."
    create:
      invalid: "Try another email address or password."
    new:
      heading: "Sign in to your account"
      email_address: "Email address"
      password: "Password"
      forgot_password: "Forgot password?"
      submit: "Sign in"
  passwords:
    rate_limited: "Try again later."
    invalid_token: "Password reset link is invalid or has expired."
    create:
      sent: "Password reset instructions sent (if user with that email address exists)."
    update:
      reset: "Password has been reset."
      mismatch: "Passwords did not match."
    new:
      heading: "Reset your password"
      email_address: "Email address"
      submit: "Email reset instructions"
      back: "Back to sign in"
    edit:
      heading: "Choose a new password"
      password: "New password"
      password_confirmation: "Repeat new password"
      submit: "Save"
  YAML

  append_to_file "db/seeds.rb" do
    <<~RUBY
    User.find_or_create_by!(email_address: 'dev@localhost.test') do |user|
      user.password = 'password'
      user.password_confirmation = 'password'
    end
    RUBY
  end

  rails_command "db:migrate"
  rails_command "db:seed"
  commit "Generate authentication"
end
