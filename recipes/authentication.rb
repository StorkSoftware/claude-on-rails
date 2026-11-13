# Prepares the databases, runs the authentication generator and seeds a
# development user.
after_bundle do
  rails_command "db:prepare"

  generate "authentication"

  # Replaces the generator's sign-in and password views with Tailwind Plus
  # forms (labels, dark mode, copy in en.yml).
  directory "recipes/authentication", ".", force: true
  append_to_file "config/locales/en.yml", <<-YAML
  sessions:
    new:
      heading: "Sign in to your account"
      email_address: "Email address"
      password: "Password"
      forgot_password: "Forgot password?"
      submit: "Sign in"
  passwords:
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
