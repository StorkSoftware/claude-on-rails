require "simplecov"

SimpleCov.skip "/test/"
SimpleCov.skip "/config/"
SimpleCov.skip "/vendor/"
SimpleCov.skip "/lib/tasks/"
SimpleCov.start "rails"

SimpleCov.minimum_coverage(80)
