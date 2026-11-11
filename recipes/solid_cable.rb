# `rails new` already ran the solid_cable installer; this only switches
# development from the async adapter to solid_cable.
after_bundle do
  gsub_file "config/cable.yml", /^development:\n  adapter: async\n/ do
    <<~YAML
      development:
        adapter: solid_cable
        connects_to:
          database:
            writing: cable
        polling_interval: 0.1.seconds
        message_retention: 1.day
    YAML
  end

  commit "Use Solid Cable in development"
end
