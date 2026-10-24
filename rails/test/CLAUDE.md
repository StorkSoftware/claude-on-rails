# Testing

- Framework: **Minitest** with fixtures (not FactoryBot); `fixtures :all` loads
  every fixture for every test.
- Integration tests get `SessionTestHelper` automatically (included via `on_load` hook):
  - `sign_in_as(user)` — creates a session and sets the signed cookie
  - `sign_out` — destroys the session and clears the cookie
- System tests use Capybara + Selenium.
- Write tests for new features. Prefer integration tests for request flows, unit
  tests for model logic. Plain Ruby service objects are unit-tested directly.

## Parallel tests

Unit and integration tests run in parallel above the threshold set in
[test_helper.rb](test_helper.rb). System tests are pinned to a single
worker in
[application_system_test_case.rb](application_system_test_case.rb)
because they drive a real browser against one server.
