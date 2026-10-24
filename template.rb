require_relative 'database_install'
require_relative 'home_install'
require_relative 'seeds_install'
require_relative 'setup_install'
require_relative 'solid_cable_install'
require_relative 'solid_queue_install'
require_relative 'simplecov_install'

def source_paths
  [ __dir__ ] + super
end

directory "rails", "."

gem "lucide-rails"

gem_group :test do
  gem "simplecov", require: false
end

patch_test_helper

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
if use_llm
  gem "ruby_llm"
end

after_bundle do
  git :init
  git add: ".", commit: %(-m 'Initial commit')

  patch_database_config(app_name)
  git add: ".", commit: %(-m 'Add cache, queue and cable databases for development')

  patch_setup
  git add: ".", commit: %(-m 'Link untracked files into worktrees in bin/setup')

  # `rails new` already ran the solid_cable, solid_cache and solid_queue
  # installers; re-running them changes nothing, and committing an empty
  # step makes `git commit` fail and abort the template.
  patch_cable_config
  git add: ".", commit: %(-m 'Use Solid Cable in development')

  patch_queue_config
  git add: ".", commit: %(-m 'Use Solid Queue in development')

  rails_command "db:prepare"

  generate "authentication"
  patch_seeds
  rails_command "db:migrate"
  rails_command "db:seed"
  git add: ".", commit: %(-m 'Generate authentication')

  install_home
  git add: ".", commit: %(-m 'Add home page as root')

  if use_llm
    generate "ruby_llm:install"
    rails_command "db:migrate"
    git add: ".", commit: %(-m 'Install RubyLLM')
  end
end
