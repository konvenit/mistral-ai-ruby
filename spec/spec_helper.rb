# frozen_string_literal: true

require "bundler/setup"
require "vcr"
require "webmock/rspec"
require "mistral-ai"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Filter out lines from RSpec backtrace
  config.filter_run_when_matching :focus
  config.run_all_when_everything_filtered = true

  # Use color output
  config.color = true

  # Use documentation format
  config.default_formatter = "doc" if config.files_to_run.one?
end

# VCR configuration for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i[method uri body]
  }

  # Filter sensitive data
  config.filter_sensitive_data("<API_KEY>") { ENV.fetch("MISTRAL_API_KEY", nil) }
  config.filter_sensitive_data("<API_KEY>") do |interaction|
    auth_header = interaction.request.headers["Authorization"]&.first
    auth_header.split(" ", 2).last if auth_header&.start_with?("Bearer ")
  end
end

# Helper to create a test client
def test_client(api_key: "test-api-key")
  MistralAI::Client.new(
    api_key: api_key,
    base_url: "https://api.mistral.ai",
    timeout: 30
  )
end
