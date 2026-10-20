def patch_seeds
  append_to_file "db/seeds.rb" do
    <<~RUBY
    User.find_or_create_by!(email_address: 'dev@localhost.test') do |user|
      user.password = 'password'
      user.password_confirmation = 'password'
    end
    RUBY
  end
end
