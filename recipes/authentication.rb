# Prepares the databases, runs the authentication generator and seeds a
# development user.
after_bundle do
  rails_command "db:prepare"

  generate "authentication"

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
