# Adds `bin/ci --with-system-tests` and a pre-push hook that runs bin/ci,
# activated by bin/setup.
after_bundle do
  gsub_file "config/ci.rb", %r{^  # Optional: Run system tests\n  # step "Tests: System", "bin/rails test:system"\n} do
    <<-RUBY
  # System tests drive a real browser, so they only run with --with-system-tests.
  step "Tests: System", "bin/rails test:system" if ARGV.include?("--with-system-tests")
    RUBY
  end

  create_file ".githooks/pre-push" do
    <<~SH
      #!/bin/sh
      # Refuses a push that would fail CI. Activated by bin/setup.
      exec bin/ci
    SH
  end
  chmod ".githooks/pre-push", 0755

  inject_into_file "bin/setup", before: %(  puts "\\n== Preparing database =="\n) do
    <<-RUBY
  if File.exist?(".git")
    puts "\\n== Activating git hooks =="
    system! "git config core.hooksPath .githooks"
  end

    RUBY
  end

  commit "Add bin/ci --with-system-tests and a pre-push hook"
end
