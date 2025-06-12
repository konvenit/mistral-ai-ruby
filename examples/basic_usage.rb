#!/usr/bin/env ruby
# frozen_string_literal: true

# Add the lib directory to the load path for development
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "mistral_ai"

puts "=== Mistral AI Ruby Client - Phase 1 Demo ==="
puts

# 1. Global Configuration
puts "1. Setting up global configuration:"
MistralAI.configure do |config|
  config.api_key = "demo-api-key"
  config.base_url = "https://api.mistral.ai"
  config.timeout = 30
  config.max_retries = 3
end

puts "   ✓ API Key: #{MistralAI.configuration.api_key}"
puts "   ✓ Base URL: #{MistralAI.configuration.base_url}"
puts "   ✓ Timeout: #{MistralAI.configuration.timeout}s"
puts "   ✓ Max Retries: #{MistralAI.configuration.max_retries}"
puts

# 2. Creating a client with global config
puts "2. Creating client with global configuration:"
global_client = MistralAI.client
puts "   ✓ Global client created with API key: #{global_client.configuration.api_key}"
puts

# 3. Creating a client with custom config
puts "3. Creating client with custom configuration:"
custom_client = MistralAI::Client.new(
  api_key: "custom-api-key",
  base_url: "https://custom.mistral.ai",
  timeout: 60
)
puts "   ✓ Custom client created"
puts "   ✓ API Key: #{custom_client.configuration.api_key}"
puts "   ✓ Base URL: #{custom_client.configuration.base_url}"
puts "   ✓ Timeout: #{custom_client.configuration.timeout}s"
puts

# 4. Accessing resources (stubbed in Phase 1)
puts "4. Accessing API resources:"
puts "   ✓ Chat resource: #{global_client.chat.class}"
puts "   ✓ Agents resource: #{global_client.agents.class}"
puts

# 5. Demonstrating error handling
puts "5. Error handling demo:"
begin
  client_without_key = MistralAI::Client.new
  client_without_key.configuration.validate!
rescue MistralAI::ConfigurationError => e
  puts "   ✓ Configuration error caught: #{e.message}"
end
puts

puts "=== Phase 1 Complete! ==="
puts "Ready for Phase 2: Chat API Implementation"
puts "Ready for Phase 3: Agents API Implementation" 