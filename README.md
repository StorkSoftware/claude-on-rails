# Rails application template

A `rails new` template that bootstraps a Rails 8 app with a set of gems and a
generic, project-agnostic set of `CLAUDE.md` files for Claude Code.

## Contents

| Path | Purpose |
| --- | --- |
| [template.rb](template.rb) | The application template passed to `rails new -m`: prompts, shared gems and the ordered list of recipes |
| [recipes/](recipes/) | One file per step. Each recipe adds its own gems, applies its patch and makes its own commit |
| [rails/](rails/) | Copied verbatim into the new app's root, keeping its structure |

### Adding a recipe

Create `recipes/<name>.rb` and add `recipe "<name>"` to `template.rb` where
the step belongs. Recipes run inside the template's generator, so they can
use any template action. Wrap work that needs installed gems or the initial
commit in `after_bundle`, and end it with `commit "<message>"`. `after_bundle`
blocks run in the order the recipes are applied, so the recipe list in
`template.rb` sets the commit order.

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
| `TEMPLATE_STRIPE` | Do you need stripe? (`stripe`) |
| `TEMPLATE_POSTMARK` | Will you use postmark for receiving emails? (`postmark-rails`) |
| `TEMPLATE_LLM` | Do you need LLM support? (`ruby_llm`) |

```bash
TEMPLATE_2FA=y TEMPLATE_STRIPE=n TEMPLATE_POSTMARK=n TEMPLATE_LLM=y \
  rails new my_app -d postgresql --css tailwind -m ~/Development/Claude/template.rb
```

### What the template does

1. Copies everything in `rails/` into the new app.
2. Adds gems:
   - always: `lucide-rails`, `simplecov` (test), `hotwire-spark` (development);
   - on request: `rotp` + `rqrcode` (2FA), `stripe`, `postmark-rails`,
     `ruby_llm`.
3. Prepends the SimpleCov setup from [recipes/simplecov.rb](recipes/simplecov.rb) to `test/test_helper.rb`, so coverage
   is reported to `coverage/index.html` on every test run (minimum 80%).
4. After `bundle install`, commits each step separately:

   | Commit | Recipe | Step |
   | --- | --- | --- |
   | `Initial commit` | | The generated app |
   | `Add cache, queue and cable databases for development` | [database](recipes/database.rb) | Splits development in `config/database.yml` into `primary`, `cache`, `queue` and `cable`, with per-worktree names |
   | `Link untracked files into worktrees in bin/setup` | [setup](recipes/setup.rb) | Symlinks `.env*` and key files from the main checkout when `bin/setup` runs in a worktree |
   | `Use Solid Cable in development` | [solid_cable](recipes/solid_cable.rb) | Switches development to the `solid_cable` adapter in `config/cable.yml` |
   | `Use Solid Queue in development` | [solid_queue](recipes/solid_queue.rb) | Sets the `solid_queue` job adapter and queue database in `config/environments/development.rb` |
   | `Generate authentication` | [authentication](recipes/authentication.rb) | Runs `db:prepare`, the authentication generator and its migration, and seeds `dev@localhost.test` / `password` |
   | `Add home page as root` | [home](recipes/home.rb) | Generates `HomeController#index` and points `root` at it |
   | `Install RubyLLM` | [ruby_llm](recipes/ruby_llm.rb) | Only if chosen: runs `ruby_llm:install` and its migrations |

## After generating

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
