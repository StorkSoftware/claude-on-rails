# Installs RubyLLM and its migrations.
gem "ruby_llm"

after_bundle do
  generate "ruby_llm:install"
  rails_command "db:migrate"
  commit "Install RubyLLM"
end
