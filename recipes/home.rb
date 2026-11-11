# Adds a signed-in home page as the root route, which the authentication
# generator redirects to after sign-in.
after_bundle do
  generate "controller", "home", "index", "--skip-routes"
  route 'root "home#index"'

  create_file "test/controllers/home_controller_test.rb", force: true do
    <<~RUBY
      require "test_helper"

      class HomeControllerTest < ActionDispatch::IntegrationTest
        test "should get index" do
          sign_in_as users(:one)
          get root_url
          assert_response :success
        end

        test "should redirect to sign in when signed out" do
          get root_url
          assert_redirected_to new_session_url
        end
      end
    RUBY
  end

  commit "Add home page as root"
end
