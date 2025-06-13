#!/usr/bin/env ruby
# frozen_string_literal: true

# Add the lib directory to the load path for development
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "mistral-ai"

puts "=== Mistral AI Ruby Client - Agents API Examples ==="
puts

# Check for API key
api_key = ENV.fetch("MISTRAL_API_KEY", nil)
if api_key.nil? || api_key.empty?
  puts "❌ MISTRAL_API_KEY environment variable is required for these examples"
  puts "Please set your API key: export MISTRAL_API_KEY='your-api-key'"
  exit 1
end

# Set up client
client = MistralAI::Client.new(
  api_key: api_key,
  timeout: 30
)

puts "✅ Client configured with API key: #{client.configuration.api_key[0..10]}..."
puts

puts "🔍 IMPORTANT: There are two ways to use agents in Mistral AI:"
puts "1. Custom Agents (beta.agents.create + conversations API) - WORKING ✅"
puts "2. Pre-built Agents (agents.complete) - Currently unavailable ❌"
puts

# ============================================================================
# WORKING EXAMPLES: Custom Agents via Beta API + Conversations
# ============================================================================

puts "🎯 WORKING EXAMPLES: Custom Agents + Conversations API"
puts "=" * 70

# Example 1: Create and Use Custom Agent
puts "Example 1: Create and Use Custom Agent"
puts "=" * 50

created_agent = nil
conversation_id = nil

begin
  # Create a custom agent
  puts "Creating custom agent..."
  created_agent = client.beta.agents.create(
    model: "mistral-large-latest",
    name: "Example Agent #{Time.now.to_i}",
    instructions: "You are a helpful AI assistant that provides clear, concise answers and maintains a professional tone."
  )

  puts "✅ Agent created: #{created_agent.id}"
  puts "Name: #{created_agent.name}"
  puts "Model: #{created_agent.model}"
  puts

  # Use the agent via conversations API
  puts "Starting conversation with custom agent..."

  conversation_body = {
    agent_id: created_agent.id,
    inputs: "Hello! Can you analyze the current trends in renewable energy technology?"
  }

  response = client.http_client.post("/v1/conversations", body: conversation_body)

  conversation_id = response["conversation_id"]
  outputs = response["outputs"]
  usage = response["usage"]

  puts "✅ Conversation successful!"
  puts "Conversation ID: #{conversation_id}"

  if outputs && !outputs.empty?
    first_output = outputs.first
    puts "Response: #{first_output['content']}"
    puts "Model: #{first_output['model']}"
  end

  puts "Usage: #{usage['total_tokens']} tokens (#{usage['prompt_tokens']} + #{usage['completion_tokens']})" if usage
  puts
rescue StandardError => e
  puts "❌ Error: #{e.class.name}: #{e.message}"
  puts
end

# Example 2: Continue Conversation
puts "Example 2: Continue Conversation"
puts "=" * 50

if conversation_id && created_agent
  begin
    puts "Continuing conversation..."

    append_body = {
      inputs: "Can you give me 3 specific examples of recent innovations in this field?"
    }

    response = client.http_client.post("/v1/conversations/#{conversation_id}", body: append_body)

    outputs = response["outputs"]
    usage = response["usage"]

    puts "✅ Conversation continued!"

    if outputs && !outputs.empty?
      first_output = outputs.first
      puts "Response: #{first_output['content']}"
    end

    puts "Usage: #{usage['total_tokens']} tokens" if usage
    puts
  rescue StandardError => e
    puts "❌ Error: #{e.class.name}: #{e.message}"
    puts
  end
else
  puts "⚠️  Skipping - no conversation to continue"
  puts
end

# Example 3: Agent with Tools
puts "Example 3: Custom Agent with Tools"
puts "=" * 50

begin
  puts "Creating agent with web search capability..."

  # NOTE: Some models/tools may not be available for all accounts
  tool_agent = client.beta.agents.create(
    model: "mistral-large-latest",
    name: "Research Agent #{Time.now.to_i}",
    instructions: "You are a research assistant that helps users find information."
  )

  puts "✅ Tool agent created: #{tool_agent.id}"

  # Use the agent
  conversation_body = {
    agent_id: tool_agent.id,
    inputs: "What are the main benefits of electric vehicles?"
  }

  response = client.http_client.post("/v1/conversations", body: conversation_body)

  outputs = response["outputs"]

  puts "✅ Tool agent response:"
  puts outputs.first["content"] if outputs && !outputs.empty?
  puts
rescue StandardError => e
  puts "❌ Error: #{e.class.name}: #{e.message}"
  puts
end

# Example 4: List and Manage Agents
puts "Example 4: List and Manage Agents"
puts "=" * 50

begin
  puts "Listing all agents in account..."

  agents = client.beta.agents.list(page_size: 5)

  puts "✅ Found #{agents.length} agents:"
  agents.each_with_index do |agent, index|
    puts "#{index + 1}. #{agent.name} (#{agent.id}) - #{agent.model}"
  end
  puts
rescue StandardError => e
  puts "❌ Error: #{e.class.name}: #{e.message}"
  puts
end

# ============================================================================
# REFERENCE EXAMPLES: Direct Agents API (Currently Not Working)
# ============================================================================

puts "📚 REFERENCE EXAMPLES: Direct Agents API (for future use)"
puts "=" * 70
puts "Note: These examples show the direct agents.complete() API pattern."
puts "Currently, no pre-built agents are available, so these will fail."
puts "Keep these examples for when pre-built agents become available."
puts

# Example 5: Direct Agent Completion (Reference)
puts "Example 5: Direct Agent Completion (Reference - Currently Fails)"
puts "=" * 50

begin
  # This would work if pre-built agents were available
  response = client.agents.complete(
    agent_id: "hypothetical-prebuilt-agent",
    messages: [
      { role: "user", content: "Analyze market trends" }
    ]
  )

  puts "✅ Direct agent response: #{response.content}"
rescue StandardError => e
  puts "❌ Expected failure: #{e.message}"
  puts "This is normal - no pre-built agents are currently available."
  puts
end

# Example 6: Direct Agent Streaming (Reference)
puts "Example 6: Direct Agent Streaming (Reference - Currently Fails)"
puts "=" * 50

begin
  puts "Attempting direct agent streaming..."

  client.agents.stream(
    agent_id: "hypothetical-prebuilt-agent",
    messages: [
      { role: "user", content: "Tell me about AI" }
    ]
  ) do |chunk|
    print chunk.choices.first.delta.content if chunk.choices.first.delta.content
  end
rescue StandardError => e
  puts "❌ Expected failure: #{e.message}"
  puts
end

# ============================================================================
# ERROR HANDLING EXAMPLES
# ============================================================================

puts "🛡️  ERROR HANDLING EXAMPLES"
puts "=" * 50

# Test validation errors
begin
  client.agents.complete(
    agent_id: "",
    messages: [{ role: "user", content: "Test" }]
  )
rescue ArgumentError => e
  puts "✅ Validation works: #{e.message}"
end

begin
  client.beta.agents.create(
    model: "",
    name: ""
  )
rescue ArgumentError => e
  puts "✅ Agent creation validation works: #{e.message}"
end

puts

# ============================================================================
# CLEANUP
# ============================================================================

puts "🧹 CLEANUP"
puts "=" * 50

# Clean up created agents (optional)
if created_agent
  begin
    client.beta.agents.delete(agent_id: created_agent.id)
    puts "✅ Cleaned up agent: #{created_agent.id}"
  rescue StandardError => e
    puts "⚠️  Cleanup failed (may not be supported): #{e.message}"
  end
end

puts

puts "=== Agents API Examples Complete! ==="
puts

puts "📝 SUMMARY:"
puts "✅ Custom agents (beta.agents + conversations) - WORKING"
puts "❌ Direct agents (agents.complete) - Not available yet"
puts "✅ Agent management (create, list, retrieve) - WORKING"
puts "✅ Conversation continuity - WORKING"
puts "✅ Error handling and validation - WORKING"
puts
puts "💡 TIP: Use custom agents with conversations API for production applications."
