def patch_database_config(app_name)
  # A linked git worktree has a `.git` file instead of a directory. Give each
  # worktree its own databases so parallel checkouts don't share data.
  prepend_to_file 'config/database.yml' do
    <<~ERB
      <%
        worktree = File.file?(Rails.root.join(".git")) ? Rails.root.basename.to_s : nil
        suffix   = ENV.fetch("DB_SUFFIX") { worktree ? "_" + worktree.gsub(/\\W/, "_")[0, 30] : "" }
      %>
    ERB
  end

  gsub_file 'config/database.yml', /^development:\n  <<: \*default\n  database: #{app_name}_development\n/ do
    <<~YAML
      development:
        primary:
          <<: *default
          database: #{app_name}_development<%= suffix %>
        cache:
          <<: *default
          database: #{app_name}_development_cache<%= suffix %>
          migrations_paths: db/cache_migrate
        queue:
          <<: *default
          database: #{app_name}_development_queue<%= suffix %>
          migrations_paths: db/queue_migrate
        cable:
          <<: *default
          database: #{app_name}_development_cable<%= suffix %>
          migrations_paths: db/cable_migrate
    YAML
  end

  gsub_file 'config/database.yml', /^test:\n  <<: \*default\n  database: #{app_name}_test\n/ do
    <<~YAML
      test:
        <<: *default
        database: #{app_name}_test<%= suffix %>
    YAML
  end
end
