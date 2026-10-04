def patch_test_helper
  prepend_to_file 'test/test_helper.rb' do
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
end
