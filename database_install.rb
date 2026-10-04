def patch_database_config(app_name)
  gsub_file 'config/database.yml', /^development:\n  <<: \*default\n  database: #{app_name}_development\n/ do
    <<~YAML
      development:
        primary:
          <<: *default
          database: #{app_name}_development
        cache:
          <<: *default
          database: #{app_name}_development_cache
          migrations_paths: db/cache_migrate
        queue:
          <<: *default
          database: #{app_name}_development_queue
          migrations_paths: db/queue_migrate
        cable:
          <<: *default
          database: #{app_name}_development_cable
          migrations_paths: db/cable_migrate
    YAML
  end
end
