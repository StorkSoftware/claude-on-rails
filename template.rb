require "active_support/encrypted_configuration"

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

# The app's encrypted credentials for one environment, which the credentials
# recipe splits into config/credentials/<environment>.{yml.enc,key}.
def credentials_for(environment)
  ActiveSupport::EncryptedConfiguration.new(
    config_path: File.join(destination_root, "config/credentials/#{environment}.yml.enc"),
    key_path: File.join(destination_root, "config/credentials/#{environment}.key"),
    env_key: "RAILS_MASTER_KEY",
    raise_if_missing_key: true
  )
end

def append_credentials(environment, yaml)
  credentials = credentials_for(environment)
  credentials.write(credentials.read + yaml)
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

# Filled into rails/CLAUDE.md.tt by `directory` below.
def project_name
  app_name.titleize
end

# TEMPLATE_DESCRIPTION answers the prompt, even when empty. A blank answer
# leaves a TODO marker like the docs' other placeholders.
def project_description
  @project_description ||= begin
    answer = ENV.fetch("TEMPLATE_DESCRIPTION") { ask("Describe the project in one sentence (blank to fill in later):") }
    answer.to_s.strip.empty? ? "<!-- TODO: One-paragraph overview of the project. -->" : answer.strip
  end
end

project_description

# Asked before `directory`, because rails/CLAUDE.md.tt documents 2FA and
# Stripe only when they are installed.
@two_factor = ask?("2FA", "Do you need 2FA?")
@stripe = ask?("STRIPE", "Do you need Stripe payments?")

def two_factor?
  @two_factor
end

def stripe?
  @stripe
end

directory "rails", "."
chmod "bin/worktree-teardown", 0755

gem "lucide-rails"

gem_group :development do
  gem "hotwire-spark", "~> 0.1.13"
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
recipe "credentials"
recipe "solid_cable"
recipe "solid_queue"
recipe "authentication"
recipe "home"
recipe "two_factor" if two_factor?
recipe "system_tests"
recipe "ci"
recipe "csp"
recipe "stripe" if stripe?
recipe "ruby_llm" if use_llm
