# `rails new` already ran the solid_queue installer; this only makes
# development use it.
after_bundle do
  inject_into_file "config/environments/development.rb", before: /^end\s*\z/ do
    <<-RUBY

  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }
  config.solid_queue.logger = ActiveSupport::Logger.new(STDOUT)
    RUBY
  end

  commit "Use Solid Queue in development"
end
