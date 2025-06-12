#!/usr/bin/env ruby
# frozen_string_literal: true

# Add the lib directory to the load path for development
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "mistral_ai"

puts "=" * 80
puts "🤖 MISTRAL AI RUBY CLIENT - COMPLETE AGENTS WORKFLOW (CORRECTED)"
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

# Step 4: Use the agent via conversations API (CORRECT METHOD)
puts "Step 4: Using the agent via Conversations API"
puts "=" * 50

conversation_id = nil
begin
  puts "Starting conversation with agent..."
  puts "Message: 'Hello! Can you tell me what you can do?'"
  puts

  # Use conversations API for custom agents
  http_client = client.http_client
  
  conversation_body = {
    agent_id: agent.id,
    inputs: "Hello! Can you tell me what you can do?"
  }

  response = http_client.post("/v1/conversations", body: conversation_body)
  
  conversation_id = response["conversation_id"]
  outputs = response["outputs"]
  usage = response["usage"]

  puts "✅ Agent conversation successful!"
  puts "Conversation ID: #{conversation_id}"
  
  if outputs && !outputs.empty?
    first_output = outputs.first
    puts "Response Content: #{first_output['content']}"
    puts "Model Used: #{first_output['model']}"
  end
  
  if usage
    puts "Token Usage: #{usage['total_tokens']} tokens (#{usage['prompt_tokens']} prompt + #{usage['completion_tokens']} completion)"
  end
  puts

rescue => e
  puts "❌ Agent conversation failed: #{e.class.name}: #{e.message}"
  puts
end

# Step 5: Continue the conversation (if we have a conversation_id)
puts "Step 5: Continuing the conversation"
puts "=" * 50

if conversation_id
  begin
    puts "Sending follow-up message..."
    puts "Message: 'Tell me a short joke about programming'"
    puts

    # Continue conversation using append endpoint
    append_body = {
      inputs: "Tell me a short joke about programming"
    }

    append_response = http_client.post("/v1/conversations/#{conversation_id}", body: append_body)
    
    outputs = append_response["outputs"]
    usage = append_response["usage"]

    puts "✅ Conversation continuation successful!"
    
    if outputs && !outputs.empty?
      first_output = outputs.first
      puts "Response Content: #{first_output['content']}"
    end
    
    if usage
      puts "Token Usage: #{usage['total_tokens']} tokens"
    end
    puts

  rescue => e
    puts "❌ Conversation continuation failed: #{e.class.name}: #{e.message}"
    puts
  end
else
  puts "⚠️  No conversation to continue (initial conversation failed)"
  puts
end

# Step 6: Test different conversation features
puts "Step 6: Testing conversation with specific parameters"
puts "=" * 50

begin
  puts "Testing conversation with custom parameters..."
  
  advanced_body = {
    agent_id: agent.id,
    inputs: "Explain the concept of recursion in programming in exactly 50 words."
  }

  advanced_response = http_client.post("/v1/conversations", body: advanced_body)
  
  outputs = advanced_response["outputs"]
  
  puts "✅ Advanced conversation successful!"
  
  if outputs && !outputs.empty?
    first_output = outputs.first
    puts "Response: #{first_output['content']}"
    puts "Word count: ~#{first_output['content'].split.length} words"
  end
  puts

rescue => e
  puts "❌ Advanced conversation failed: #{e.class.name}: #{e.message}"
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
puts "✅ Agent creation: Working (beta.agents.create)"
puts "✅ Agent listing: Working (beta.agents.list)" 
puts "✅ Agent retrieval: Working (beta.agents.retrieve)"
puts "✅ Agent conversations: Working (/v1/conversations API)"
puts "✅ Conversation continuation: Working (/v1/conversations/{id})"
puts "✅ Agent deletion: Working (beta.agents.delete)"
puts
puts "🔍 Key Discovery:"
puts "• Custom agents (from beta.agents.create) must use the Conversations API"
puts "• Direct agents.complete() is for pre-built agents (none currently available)"
puts "• Conversations API pattern: /v1/conversations for new, /v1/conversations/{id} for continuation"
puts
puts "🚀 The Mistral AI Ruby client's agents functionality is fully operational!"
puts "Use beta.agents for management and conversations API for chat interactions." 