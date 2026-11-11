def source_paths
  [ __dir__ ] + super
end

# Recipes are evaluated in this generator, so they can use every template
# action plus the helpers below. Their `after_bundle` blocks run in the order
# the recipes are applied, which is the order of the commits.
def recipe(name)
  apply "recipes/#{name}.rb"
end

def commit(message)
  git add: ".", commit: %(-m '#{message}')
end

# Asks a yes/no question unless TEMPLATE_<KEY> answers it, so the template can
# run without a terminal: TEMPLATE_2FA=y TEMPLATE_STRIPE=n rails new ...
def ask?(key, question)
  value = ENV["TEMPLATE_#{key}"]
  return yes?(question) if value.nil? || value.strip.empty?

  case value.strip.downcase
  when "y", "yes", "true", "1" then true
  when "n", "no", "false", "0" then false
  else abort_template "TEMPLATE_#{key}=#{value} is not a yes/no answer. Use y or n."
  end
end

# `rails new` has already written the app's files when the template runs, so
# stopping here leaves a partial app directory behind.
def abort_template(message)
  say_error message, :red
  say_error "Remove #{destination_root} before running `rails new` again.", :red
  exit 1
end

# The copied CLAUDE.md files describe a PostgreSQL + Tailwind stack.
required = { database: "postgresql", css: "tailwind" }
mismatched = required.reject { |name, value| options[name] == value }
if mismatched.any?
  got = mismatched.map { |name, _| "--#{name}=#{options[name] || "(none)"}" }.join(", ")
  abort_template "This template requires `-d postgresql --css tailwind`; got #{got}."
end

directory "rails", "."
chmod "bin/worktree-teardown", 0755

gem "lucide-rails"

gem_group :development do
  gem "hotwire-spark", "~> 0.1.13"
end

if ask?("2FA", "Do you need 2FA?")
  gem "rotp"
  gem "rqrcode"
end

if ask?("STRIPE", "Do you need stripe?")
  gem "stripe"
end

if ask?("POSTMARK", "Will you use postmark for receiving emails?")
  gem "postmark-rails"
end

use_llm = ask?("LLM", "Do you need LLM support?")

after_bundle do
  git :init
  commit "Initial commit"
end

recipe "simplecov"
recipe "database"
recipe "setup"
recipe "solid_cable"
recipe "solid_queue"
recipe "authentication"
recipe "home"
recipe "ruby_llm" if use_llm
