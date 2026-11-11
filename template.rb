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

directory "rails", "."
chmod "bin/worktree-teardown", 0755

gem "lucide-rails"

gem_group :development do
  gem "hotwire-spark", "~> 0.1.13"
end

if yes?("Do you need 2FA?")
  gem "rotp"
  gem "rqrcode"
end

if yes?("Do you need stripe?")
  gem "stripe"
end

if yes?("Will you use postmark for receiving emails?")
  gem "postmark-rails"
end

use_llm = yes?("Do you need LLM support?")

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
