# Installs RubyLLM with its API keys read from each environment's credentials,
# and stops tests from reaching the network.
gem "ruby_llm"

gem_group :test do
  gem "webmock"
end

after_bundle do
  initializer "ruby_llm.rb", <<~RUBY
    RubyLLM.configure do |config|
      credentials = Rails.application.credentials.ruby_llm || {}
      config.anthropic_api_key = credentials[:anthropic_api_key]
      config.openai_api_key = credentials[:openai_api_key]
    end
  RUBY

  %w[development production].each do |environment|
    append_credentials environment, <<~YAML

      ruby_llm:
        anthropic_api_key:
        openai_api_key:
    YAML
  end

  # Any HTTP call a test makes outside localhost fails, so no test can spend
  # money on an LLM provider. System tests still reach Chrome on localhost.
  inject_into_file "test/test_helper.rb", after: %(require "rails/test_help"\n) do
    <<~RUBY
      require "webmock/minitest"

      WebMock.disable_net_connect!(allow_localhost: true)
    RUBY
  end

  create_file "test/network_test.rb", <<~RUBY
    require "test_helper"

    class NetworkTest < ActiveSupport::TestCase
      test "tests cannot reach an LLM provider" do
        assert_raises(WebMock::NetConnectNotAllowedError) do
          Net::HTTP.get(URI("https://api.anthropic.com/v1/models"))
        end
      end
    end
  RUBY

  commit "Install RubyLLM"
end
