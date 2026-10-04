# Rails application template

A `rails new` template that bootstraps a Rails 8 app with a set of gems and a
generic, project-agnostic set of `CLAUDE.md` files for Claude Code.

## Contents

| Path | Purpose |
| --- | --- |
| [template.rb](template.rb) | The application template passed to `rails new -m` |
| [simplecov.rb](simplecov.rb) | SimpleCov setup, prepended to `test/test_helper.rb` |
| [rails/](rails/) | Copied verbatim into the new app's root, keeping its structure |

`rails/` holds:

| File | Covers |
| --- | --- |
| [CLAUDE.md](rails/CLAUDE.md) | Stack, commands, checks, code style, testing, architecture, CSP, UI, commits |
| [CONTEXT.md](rails/CONTEXT.md) | Domain glossary (empty template) |
| [app/controllers/CLAUDE.md](rails/app/controllers/CLAUDE.md) | Namespacing, Pundit authorization, responses, strong parameters |
| [app/models/CLAUDE.md](rails/app/models/CLAUDE.md) | Structural map (placeholder), code ordering, deletion semantics |
| [app/views/CLAUDE.md](rails/app/views/CLAUDE.md) | Tailwind Plus components, view conventions, forms, localisation |
| [config/locales/CLAUDE.md](rails/config/locales/CLAUDE.md) | Locale structure, validation messages, copy voice |
| [db/CLAUDE.md](rails/db/CLAUDE.md) | Keeping `db/README.md` in sync, migrations, database safety |
| [db/README.md](rails/db/README.md) | Schema documentation (template) |
| [.vscode/tasks.json](rails/.vscode/tasks.json) | VS Code tasks: console, server, Tailwind watcher, jobs, coverage report |

## Usage

The template reads its files relative to its own location, so run it from a
local checkout of this repository — not from a URL.

```bash
rails new my_app -d postgresql --css tailwind -m ~/Development/Claude/template.rb
```

`-d postgresql` and `--css tailwind` match the stack the `CLAUDE.md` files
describe; the template does not set them itself.

### What the template does

1. Copies everything in `rails/` into the new app.
2. Adds gems:
   - always: `lucide-rails`, `simplecov` (test), `hotwire-spark` (development);
   - on request: `rotp` + `rqrcode` (2FA), `stripe`, `postmark-rails`,
     `ruby_llm`.
3. Prepends [simplecov.rb](simplecov.rb) to `test/test_helper.rb`, so coverage
   is reported to `coverage/index.html` on every test run (minimum 80%).
4. After `bundle install`:
   - initializes git and commits as `Initial commit`;
   - runs the Rails authentication generator (and `ruby_llm:install` if chosen);
   - installs Solid Cable, Solid Cache and Solid Queue, and configures them for
     development too: separate `cache`, `queue` and `cable` databases in
     `config/database.yml`, the `solid_cable` adapter in `config/cable.yml`,
     and the `solid_queue` job adapter in `config/environments/development.rb`;
   - runs `db:prepare` and commits as `Generate authentication`.

## After generating

### Required: generate a controller for the root route

`rails new` does not define a root route, but the authentication generator
redirects to `root_url` after sign-in. Until a root route exists,
`SessionsControllerTest#test_create_with_valid_credentials` fails with
`NameError: undefined local variable or method 'root_url'`, and so does
`bin/ci`.

The template does not add one, because where root points depends on the
project. Generate the controller yourself, then point `root` at it in
`config/routes.rb`:

- **A single public page:**

  ```bash
  bin/rails generate controller Pages home --skip-routes
  ```

  ```ruby
  root "pages#home"
  ```

- **A page inside a product area (namespace):**

  ```bash
  bin/rails generate controller Members::Dashboard show --skip-routes
  ```

  ```ruby
  root "members/dashboard#show"
  ```

`--skip-routes` stops the generator from adding a `get` route next to `root`.
Run `bin/ci` afterwards to confirm the suite passes.

### Fill in the placeholders

Every project-specific gap in the copied docs is marked with an HTML comment:

```bash
grep -rn "TODO" --include="*.md" .
```

Start with the project name and overview in `CLAUDE.md`, the roles, and the
glossary in `CONTEXT.md`.

### Set up what the docs assume

The `CLAUDE.md` files describe a few things the template does not install.
Add them, or remove the matching sections from the docs:

- **Pundit and rolify** — authorization and roles.
- **TailwindPlusServer MCP server** — `app/views/CLAUDE.md` tells Claude to
  fetch components from it. Connect it under that exact name.
- **`bin/ci` options and the pre-push hook** — `CLAUDE.md` describes
  `--with-system-tests` and a `.githooks/pre-push` hook activated by
  `bin/setup`.
- **System tests pinned to a single worker** in
  `test/application_system_test_case.rb`.
- **Strict CSP** — the policy in `config/initializers/content_security_policy.rb`
  and Active Storage in proxy mode.
