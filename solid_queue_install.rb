def patch_queue_config
  inject_into_file 'config/environments/development.rb', before: /^end\s*\z/ do
    <<-RUBY

  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }
  config.solid_queue.logger = ActiveSupport::Logger.new(STDOUT)
    RUBY
  end
end
