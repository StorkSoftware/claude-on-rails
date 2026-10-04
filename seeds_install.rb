def patch_seeds
  append_to_file "db/seeds.rb" do
    <<~RUBY
    User.create!(
      email_address: 'dev@localhost.test',
      password: 'password',
      password_confirmation: 'password'
    )
    RUBY
  end
end
