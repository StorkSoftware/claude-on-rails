# Rails application template

A `rails new` template that bootstraps a Rails 8 app with a set of gems and a
generic, project-agnostic set of `CLAUDE.md` files for Claude Code.

## Contents

| Path | Purpose |
| --- | --- |
| [template.rb](template.rb) | The application template passed to `rails new -m`: prompts, shared gems and the ordered list of recipes |
| [recipes/](recipes/) | One file per step. Each recipe adds its own gems, applies its patch and makes its own commit |
| [rails/](rails/) | Copied verbatim into the new app's root, keeping its structure |
| [bin/ci](bin/ci) | Verifies the template end to end; see [Verifying changes](#verifying-changes) |

### Adding a recipe

Create `recipes/<name>.rb` and add `recipe "<name>"` to `template.rb` where
the step belongs. Recipes run inside the template's generator, so they can
use any template action. Wrap work that needs installed gems or the initial
commit in `after_bundle`, and end it with `commit "<message>"`. `after_bundle`
blocks run in the order the recipes are applied, so the recipe list in
`template.rb` sets the commit order.

Files a recipe adds whole (controllers, views, tests) go in a folder named
after it, laid out like the app, and are copied with
`directory "recipes/<name>", "."`. The `.rb` file keeps only the patches to
files that already exist. Name a file `.tt` if it needs ERB evaluated by the
template; everything else, including `.html.erb` views, is copied as it is.
See [recipes/two_factor/](recipes/two_factor/).

`rails/` holds:

| File | Covers |
| --- | --- |
| [CLAUDE.md.tt](rails/CLAUDE.md.tt) | Stack, commands, checks, code style, testing, architecture, CSP, UI, commits. Rendered as `CLAUDE.md` with the project name, description, and Ruby and Rails versions filled in |
| [CONTEXT.md.tt](rails/CONTEXT.md.tt) | Domain glossary (empty template), rendered with the project name |
| [app/controllers/CLAUDE.md](rails/app/controllers/CLAUDE.md) | Namespacing, responses, strong parameters |
| [app/models/CLAUDE.md](rails/app/models/CLAUDE.md) | Structural map (placeholder), code ordering, deletion semantics |
| [app/views/CLAUDE.md](rails/app/views/CLAUDE.md) | Tailwind Plus components, view conventions, forms, localisation |
| [config/locales/CLAUDE.md](rails/config/locales/CLAUDE.md) | Locale structure, validation messages, copy voice |
| [db/CLAUDE.md](rails/db/CLAUDE.md) | Keeping `db/README.md` in sync, migrations, database safety |
| [db/README.md.tt](rails/db/README.md.tt) | Schema documentation, rendered with the tables the chosen options create; the `docs` recipe stamps the schema version |
| [.vscode/tasks.json](rails/.vscode/tasks.json) | VS Code tasks: console, server, Tailwind watcher, jobs, coverage report |

### Verifying changes

```bash
bin/ci              # every option on and every option off, in parallel
bin/ci on           # one combination (on or off)
bin/ci --keep off   # keep the app and its databases for debugging
```

For each combination, `bin/ci` generates a fresh app in a temp directory
(with `--no-rc`, so `~/.railsrc` doesn't affect it), then:

1. fails on generator errors or changes the template left uncommitted;
2. runs `bin/rails db:prepare` and fails on pending migrations;
3. runs the app's own `bin/ci --with-system-tests`, which needs Chrome.

Afterwards it drops the app's databases and deletes it. A failed run prints
the end of its log and keeps the log file. A full run takes about a minute.

## Usage

The template reads its files relative to its own location, so run it from a
local checkout of this repository — not from a URL.

```bash
rails new my_app -d postgresql --css tailwind -m ~/Development/Claude/template.rb
```

`-d postgresql` and `--css tailwind` match the stack the `CLAUDE.md` files
describe. The template does not set them itself, but it stops with an error if
either is missing (flags in `~/.railsrc` count). `rails new` has already
written the app's files by then, so delete the partial app directory before
running it again.

### Answering the prompts non-interactively

Each yes/no prompt can be answered with an environment variable instead.
Accepted values are `y`/`yes`/`true`/`1` and `n`/`no`/`false`/`0`. An unset or
empty variable falls back to the prompt, and any other value stops the
template.

| Variable | Prompt |
| --- | --- |
| `TEMPLATE_2FA` | Do you need 2FA? (`rotp`, `rqrcode`) |
| `TEMPLATE_STRIPE` | Do you need Stripe payments? (`stripe`, `minitest-mock`) |
| `TEMPLATE_POSTMARK` | Will you use postmark for receiving emails? (`postmark-rails`) |
| `TEMPLATE_LLM` | Do you need LLM support? (`ruby_llm`) |

The template also asks for a one-sentence project description, which becomes
the overview in the generated `CLAUDE.md`. `TEMPLATE_DESCRIPTION` answers it;
unlike the yes/no variables, setting it to an empty string counts as an answer
and leaves a `TODO` marker in place of the overview. The project name is always
the app name in title case (`my_app` becomes `My App`).

```bash
TEMPLATE_2FA=y TEMPLATE_STRIPE=n TEMPLATE_POSTMARK=n TEMPLATE_LLM=y \
TEMPLATE_DESCRIPTION="Booking system for climbing gyms." \
  rails new my_app -d postgresql --css tailwind -m ~/Development/Claude/template.rb
```

### What the template does

1. Copies everything in `rails/` into the new app.
2. Adds gems:
   - always: `lucide-rails`, `simplecov` (test), `hotwire-spark` (development);
   - on request: `rotp` + `rqrcode` (2FA), `stripe` + `minitest-mock` (test),
     `postmark-rails`, `ruby_llm`.
3. Prepends the SimpleCov setup from [recipes/simplecov.rb](recipes/simplecov.rb) to `test/test_helper.rb`, so coverage
   is reported to `coverage/index.html` on every test run (minimum 80%).
4. After `bundle install`, commits each step separately:

   | Commit | Recipe | Step |
   | --- | --- | --- |
   | `Initial commit` | | The generated app |
   | `Add cache, queue and cable databases for development` | [database](recipes/database.rb) | Splits development in `config/database.yml` into `primary`, `cache`, `queue` and `cable`, with per-worktree names |
   | `Link untracked files into worktrees in bin/setup` | [setup](recipes/setup.rb) | Symlinks `.env*` and key files from the main checkout when `bin/setup` runs in a worktree |
   | `Split credentials per environment` | [credentials](recipes/credentials.rb) | Replaces `config/credentials.yml.enc` and `config/master.key` with `config/credentials/{development,production}.yml.enc` and their own keys (production keeps `secret_key_base`), gitignores the keys, and points `.kamal/secrets` at `production.key`. Test gets no credentials; recipes put test values in `config/environments/test.rb` |
   | `Use Solid Cable in development` | [solid_cable](recipes/solid_cable.rb) | Switches development to the `solid_cable` adapter in `config/cable.yml` |
   | `Use Solid Queue in development` | [solid_queue](recipes/solid_queue.rb) | Sets the `solid_queue` job adapter and queue database in `config/environments/development.rb` |
   | `Generate authentication` | [authentication](recipes/authentication.rb) | Runs `db:prepare`, the authentication generator and its migration, replaces its sign-in and password views with Tailwind Plus forms, moves their copy and the controllers' flash messages to `en.yml`, and seeds `dev@localhost.test` / `password` |
   | `Add home page as root` | [home](recipes/home.rb) | Generates `HomeController#index`, replaces its placeholder view with a Tailwind Plus page heading (2FA and Stripe add their panels to it), gives the layout the Tailwind Plus light/dark page background, and points `root` at it |
   | `Add two-factor authentication` | [two_factor](recipes/two_factor.rb) | Only if chosen: TOTP enrolment with a QR code, a code challenge after password sign-in (expires after 5 minutes), `users.otp_secret` encrypted with keys added to the development and production credentials (fixed keys in `config/environments/test.rb`), and tests. The 2FA sections of `CLAUDE.md` are only included in this case |
   | `Add system tests pinned to a single worker` | [system_tests](recipes/system_tests.rb) | Adds `test/application_system_test_case.rb` (headless Chrome, one worker, coverage merged into the unit run) and a sign-in test that checks Turbo and Stimulus boot |
   | `Add bin/ci --with-system-tests and a pre-push hook` | [ci](recipes/ci.rb) | Adds the opt-in system test step to `config/ci.rb`, and a `.githooks/pre-push` hook running `bin/ci` that `bin/setup` activates |
   | `Enforce a same-origin Content Security Policy` | [csp](recipes/csp.rb) | Sets every fetch directive to `'self'`, `script-src` with `'strict-dynamic'` and a per-session nonce, and Active Storage proxy mode |
   | `Add Stripe Checkout and webhook callback` | [stripe](recipes/stripe.rb) | Only if chosen: a "Make a test payment" button that redirects to Stripe Checkout, a success page, signed webhooks at `/stripe/callback` stored once in `stripe_events` and handled by a job, daily cleanup of processed events after 90 days, and tests. Production refuses to boot without `stripe.secret_key` and `stripe.webhook_secret` in credentials. The Stripe sections of `CLAUDE.md` are only included in this case |
   | `Install RubyLLM` | [ruby_llm](recipes/ruby_llm.rb) | Only if chosen: runs `ruby_llm:install` and its migrations |
   | `Stamp the schema version in db/README.md` | [docs](recipes/docs.rb) | Writes the final `db/schema.rb` version into `db/README.md`, so the docs start in sync with the schema |

## After generating

### Fill in the placeholders

The template fills in what it knows: the project name, the tables its recipes
create and the schema version. Every remaining project-specific gap in the
copied docs is marked with an HTML comment:

```bash
grep -rn "TODO" --include="*.md" .
```

Start with the overview in `CLAUDE.md` if you left the description blank, and
the glossary in `CONTEXT.md`.

### Set up what the docs assume

The `CLAUDE.md` files describe a few things the template does not install.
Add them, or remove the matching sections from the docs:

- **TailwindPlusServer MCP server** — `app/views/CLAUDE.md` tells Claude to
  fetch components from it. Connect it under that exact name.

`bin/setup` points git at `.githooks`, so after it runs every `git push` runs
`bin/ci` first. Skip it for one push with `git push --no-verify`.
