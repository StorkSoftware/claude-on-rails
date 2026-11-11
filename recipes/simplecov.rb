# Reports test coverage to coverage/index.html on every run (minimum 80%).
# Runs before bundle, so the change lands in the initial commit.
gem_group :test do
  gem "simplecov", require: false
end

prepend_to_file "test/test_helper.rb" do
  <<~RUBY
    require "simplecov"

    SimpleCov.skip "/test/"
    SimpleCov.skip "/config/"
    SimpleCov.skip "/vendor/"
    SimpleCov.skip "/lib/tasks/"
    SimpleCov.start "rails"

    SimpleCov.minimum_coverage(80)

  RUBY
end

append_to_file ".gitignore", "\n# Ignore SimpleCov output.\n/coverage/\n"
