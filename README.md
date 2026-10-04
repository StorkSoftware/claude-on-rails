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

