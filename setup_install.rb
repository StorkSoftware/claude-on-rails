def patch_setup
  inject_into_file "bin/setup", after: "FileUtils.chdir APP_ROOT do\n" do
    <<-RUBY
  if File.file?(".git")
    puts "== Linking untracked files from the main checkout =="
    git_common_dir = IO.popen(%w[git rev-parse --path-format=absolute --git-common-dir], &:read).strip
    main_checkout = File.dirname(git_common_dir)
    untracked = Dir.chdir(main_checkout) { Dir.glob([ ".env*", "config/*.key", "config/credentials/*.key" ]) }
    untracked.each do |path|
      next if File.exist?(path) || File.symlink?(path)

      FileUtils.mkdir_p(File.dirname(path))
      FileUtils.ln_s(File.join(main_checkout, path), path)
      puts "  linked \#{path}"
    end
    puts
  end

    RUBY
  end
end
