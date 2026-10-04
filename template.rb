require_relative 'database_install'
require_relative 'solid_cable_install'
require_relative 'solid_queue_install'

def source_paths
  [ __dir__ ] + super
end

directory "rails", "."

gem "lucide-rails"

simplecov_rb_path = File.join(__dir__, 'simplecov.rb')
simplecov_rb = File.read(simplecov_rb_path)

prepend_to_file 'test/test_helper.rb' do
  simplecov_rb
end

gem_group :test do
  gem "simplecov", require: false
end

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

  generate "solid_cable:install"
  patch_cable_config
  git add: ".", commit: %(-m 'Install Solid Cable')

  generate "solid_cache:install"
  git add: ".", commit: %(-m 'Install Solid Cache')

  generate "solid_queue:install"
  patch_queue_config
  git add: ".", commit: %(-m 'Install Solid Queue')

  rails_command "db:prepare"

  generate "authentication"
  rails_command "db:migrate"
  git add: ".", commit: %(-m 'Generate authentication')

  if use_llm
    generate "ruby_llm:install"
    rails_command "db:migrate"
    git add: ".", commit: %(-m 'Install RubyLLM')
  end
end
