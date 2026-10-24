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
[test/test_helper.rb](test/test_helper.rb). System tests are pinned to a single
worker in
[test/application_system_test_case.rb](test/application_system_test_case.rb)
because they drive a real browser against one server.

[config/database.yml](config/database.yml) sets no `host` in development and
test, so libpq connects over a Unix socket. Adding `host: localhost` makes it a
TCP connection, which negotiates GSSAPI — and macOS's GSS framework is not
fork-safe, so workers die with a SIGSEGV inside `connect_start` that reads like
a `pg` bug but is the connection setup. If a host is ever needed on macOS, pair
it with `gssencmode: disable`. Don't reach for `PARALLEL_WORKERS=1` or a raised
threshold to make the symptom go away.