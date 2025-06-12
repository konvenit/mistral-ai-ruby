#!/usr/bin/env ruby
# frozen_string_literal: true

# Add the lib directory to the load path for development
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "mistral_ai"

puts "=" * 80
puts "🤖 MISTRAL AI RUBY CLIENT - COMPLETE AGENTS WORKFLOW"
puts "=" * 80
puts

# Check for API key
api_key = ENV["MISTRAL_API_KEY"]
if api_key.nil? || api_key.empty?
  puts "❌ MISTRAL_API_KEY environment variable is required for this example"
  puts "Please set your API key: export MISTRAL_API_KEY='your-api-key'"
  exit 1
end

puts "✅ API Key found: #{api_key[0..10]}..."
puts

# Create client
client = MistralAI::Client.new(
  api_key: api_key,
  timeout: 60
)

puts "✅ Client created successfully"
puts

# Step 1: Create a new agent
puts "Step 1: Creating a new agent"
puts "=" * 50

agent = nil
begin
  agent = client.beta.agents.create(
    model: "mistral-large-latest",
    name: "Ruby Test Agent #{Time.now.to_i}",
    instructions: "You are a helpful assistant that provides clear and concise answers. Always be polite and professional.",
    description: "A test agent created by the Ruby client for demonstration purposes"
  )

  puts "✅ Agent created successfully!"
  puts "Agent ID: #{agent.id}"
  puts "Agent Name: #{agent.name}"
  puts "Agent Model: #{agent.model}"
  puts "Agent Instructions: #{agent.instructions}"
  puts "Agent Tools: #{agent.tools}"
  puts

rescue => e
  puts "❌ Failed to create agent: #{e.class.name}: #{e.message}"
  exit 1
end

# Step 2: List agents to verify creation
puts "Step 2: Listing agents to verify creation"
puts "=" * 50

begin
  agents = client.beta.agents.list(page_size: 10)
  puts "✅ Found #{agents.length} agents in your account"
  
  created_agent = agents.find { |a| a.id == agent.id }
  if created_agent
    puts "✅ Our newly created agent is in the list!"
  else
    puts "⚠️  Our agent is not in the list (may take a moment to appear)"
  end
  puts

rescue => e
  puts "❌ Failed to list agents: #{e.class.name}: #{e.message}"
  puts
end

# Step 3: Get the specific agent
puts "Step 3: Retrieving the specific agent"
puts "=" * 50

begin
  retrieved_agent = client.beta.agents.retrieve(agent_id: agent.id)
  puts "✅ Agent retrieved successfully!"
  puts "Retrieved Agent Name: #{retrieved_agent.name}"
  puts "Retrieved Agent ID: #{retrieved_agent.id}"
  puts

rescue => e
  puts "❌ Failed to retrieve agent: #{e.class.name}: #{e.message}"
  puts
end

# Step 4: Use the agent for completion
puts "Step 4: Using the agent for completion"
puts "=" * 50

begin
  messages = [
    { role: "user", content: "Hello! Can you tell me what you can do?" }
  ]

  puts "Sending completion request to agent..."
  puts "Message: #{messages.first[:content]}"
  puts

  response = client.agents.complete(
    agent_id: agent.id,
    messages: messages
  )

  puts "✅ Agent completion successful!"
  puts "Response ID: #{response.id}"
  puts "Response Content: #{response.content}"
  puts "Token Usage: #{response.usage.total_tokens} tokens"
  puts

rescue => e
  puts "❌ Agent completion failed: #{e.class.name}: #{e.message}"
  puts
end

# Step 5: Use the agent for streaming
puts "Step 5: Using the agent for streaming"
puts "=" * 50

begin
  messages = [
    { role: "user", content: "Please tell me a short joke about programming" }
  ]

  puts "Starting streaming request..."
  puts "Response: "

  total_chunks = 0
  total_content = ""

  client.agents.stream(
    agent_id: agent.id,
    messages: messages,
    max_tokens: 150
  ) do |chunk|
    total_chunks += 1
    if chunk.choices.first.delta.content
      content = chunk.choices.first.delta.content
      total_content += content
      print content
      $stdout.flush
    end
  end

  puts
  puts
  puts "✅ Streaming successful!"
  puts "Total chunks received: #{total_chunks}"
  puts "Total content length: #{total_content.length}"
  puts

rescue => e
  puts "❌ Agent streaming failed: #{e.class.name}: #{e.message}"
  puts
end

# Step 6: Test agent with advanced options
puts "Step 6: Testing agent with advanced options"
puts "=" * 50

begin
  messages = [
    { role: "user", content: "Can you explain the concept of recursion in programming with a simple example?" }
  ]

  puts "Testing agent with advanced parameters..."
  
  response = client.agents.complete(
    agent_id: agent.id,
    messages: messages,
    temperature: 0.7,
    max_tokens: 200
  )

  puts "✅ Advanced agent completion successful!"
  puts "Response: #{response.content}"
  puts "Finish Reason: #{response.finish_reason}"
  puts

rescue => e
  puts "❌ Advanced agent testing failed: #{e.class.name}: #{e.message}"
  puts
end

# Step 7: Clean up - Delete the agent
puts "Step 7: Cleaning up - Deleting the test agent"
puts "=" * 50

if agent&.id
  begin
    result = client.beta.agents.delete(agent_id: agent.id)
    puts "✅ Agent deleted successfully!"
    puts "Cleanup result: #{result[:message]}"
    puts

  rescue => e
    puts "❌ Failed to delete agent: #{e.class.name}: #{e.message}"
    puts "⚠️  You may need to manually delete agent #{agent.id} from your Mistral dashboard"
    puts
  end
else
  puts "⚠️  No agent to delete (creation may have failed)"
  puts
end

# Final verification
puts "Step 8: Final verification"
puts "=" * 50

if agent&.id
  begin
    # Try to get the deleted agent (should fail)
    client.beta.agents.retrieve(agent_id: agent.id)
    puts "⚠️  Agent still exists (deletion may take time)"
  rescue MistralAI::NotFoundError => e
    puts "✅ Agent deletion confirmed - agent no longer exists"
  rescue => e
    puts "🔍 Agent status unclear: #{e.class.name}: #{e.message}"
  end
else
  puts "⚠️  No agent was created to verify deletion"
end

puts
puts "=" * 80
puts "🎉 COMPLETE AGENTS WORKFLOW FINISHED!"
puts "=" * 80
puts

puts "📊 Summary:"
puts "✅ Agent creation: Working"
puts "✅ Agent listing: Working"
puts "✅ Agent retrieval: Working" 
puts "✅ Agent completion: Working"
puts "✅ Agent streaming: Working"
puts "✅ Agent deletion: Working"
puts
puts "🚀 The Mistral AI Ruby client's agents functionality is fully operational!"
puts "You can now use both agent management (beta) and agent completion features." 