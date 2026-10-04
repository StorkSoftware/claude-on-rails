def patch_cable_config
  gsub_file 'config/cable.yml', /^development:\n  adapter: async\n/ do
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
end
