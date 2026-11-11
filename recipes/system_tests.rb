# Rails 8.1 ships Capybara and Selenium but no system test setup. Adds the
# base class, pinned to a single worker, and a sign-in test that fails if the
# importmap stops booting (e.g. because the CSP blocks it).
after_bundle do
  create_file "test/application_system_test_case.rb" do
    <<~RUBY
      require "test_helper"

      # Merge into the unit test coverage report instead of replacing it. The
      # 80% minimum is enforced by the unit and integration run; a few browser
      # tests alone would never reach it.
      SimpleCov.command_name "test:system"
      SimpleCov.minimum_coverage(0)

      class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
        # System tests drive a real browser against one server, so they run in a
        # single worker.
        parallelize(workers: 1)

        driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
      end
    RUBY
  end

  create_file "test/system/sign_in_test.rb" do
    <<~RUBY
      require "application_system_test_case"

      class SignInTest < ApplicationSystemTestCase
        test "signing in lands on the home page with Turbo and Stimulus running" do
          # The first page of a visit, before any session exists.
          visit new_session_url
          assert_javascript_running

          fill_in "email_address", with: users(:one).email_address
          fill_in "password", with: "password"
          click_button "Sign in"

          assert_current_path root_path
          assert_javascript_running
        end

        private
          # A CSP that blocks the importmap stops both from booting.
          def assert_javascript_running
            assert page.evaluate_script("typeof window.Turbo !== 'undefined'"), "Turbo did not load"
            assert page.evaluate_script("typeof window.Stimulus !== 'undefined'"), "Stimulus did not load"
          end
      end
    RUBY
  end

  commit "Add system tests pinned to a single worker"
end
