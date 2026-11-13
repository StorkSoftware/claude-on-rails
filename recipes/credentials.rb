# Replaces the single config/credentials.yml.enc + config/master.key with one
# encrypted file and key per environment, so a development key never decrypts
# production secrets. Test has none: its values live in
# config/environments/test.rb. Later recipes add to these files with
# append_credentials.
after_bundle do
  shared = ActiveSupport::EncryptedConfiguration.new(
    config_path: File.join(destination_root, "config/credentials.yml.enc"),
    key_path: File.join(destination_root, "config/master.key"),
    env_key: "RAILS_MASTER_KEY",
    raise_if_missing_key: true
  )
  contents = {
    # rails new put secret_key_base here; development and test generate their own.
    "production" => shared.read,
    "development" => "# Development credentials. Edit with `bin/rails credentials:edit --environment development`.\n"
  }

  contents.each_key do |environment|
    key_path = "config/credentials/#{environment}.key"
    create_file key_path, ActiveSupport::EncryptedConfiguration.generate_key
    chmod key_path, 0600
    credentials_for(environment).write(contents.fetch(environment))
  end

  remove_file "config/credentials.yml.enc"
  remove_file "config/master.key"

  append_to_file ".gitignore", "/config/credentials/*.key\n"
  gsub_file ".kamal/secrets", "config/master.key", "config/credentials/production.key"
  gsub_file "Dockerfile", "config/master.key", "config/credentials/production.key"

  commit "Split credentials per environment"
end
