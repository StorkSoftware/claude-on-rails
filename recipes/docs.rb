# Stamps the final schema version into db/README.md, once every recipe's
# migrations have run.
after_bundle do
  version = File.read(File.join(destination_root, "db/schema.rb"))[/define\(version: ([\d_]+)\)/, 1]
  abort_template("db/schema.rb has no define(version:) line; update recipes/docs.rb") unless version

  gsub_file "db/README.md", "<!-- TODO: version -->", version
  commit "Stamp the schema version in db/README.md"
end
