#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/mistral-ai"

# Phase 2 Chat API Examples
# These examples demonstrate the chat completion and streaming functionality

# Configure the client
MistralAI.configure do |config|
  config.api_key = ENV["MISTRAL_API_KEY"] || "your-api-key-here"
end

client = MistralAI.client

puts "=== Phase 2: Chat API Examples ==="
puts

# Example 1: Simple Chat Completion
puts "1. Simple Chat Completion"
puts "-" * 30

begin
  response = client.chat.complete(
    model: "mistral-small-latest",
    messages: [
      { role: "user", content: "What is the capital of France?" }
    ]
  )

  puts "Response: #{response.content}"
  puts "Model: #{response.model}"
  puts "Usage: #{response.usage.total_tokens} tokens"
  puts
rescue StandardError => e
  puts "Error: #{e.message}"
  puts
end

# Example 2: Multi-turn Conversation
puts "2. Multi-turn Conversation"
puts "-" * 30

begin
  messages = [
    { role: "system", content: "You are a helpful assistant that speaks like a pirate." },
    { role: "user", content: "Hello, how are you?" },
    { role: "assistant", content: "Ahoy there, matey! I be doin' fine, thank ye fer askin'!" },
    { role: "user", content: "Can you tell me about Ruby programming?" }
  ]

  response = client.chat.complete(
    model: "mistral-small-latest",
    messages: messages,
    temperature: 0.7,
    max_tokens: 150
  )

  puts "Pirate Assistant: #{response.content}"
  puts
rescue StandardError => e
  puts "Error: #{e.message}"
  puts
end

# Example 3: Chat Completion with Advanced Options
puts "3. Chat Completion with Advanced Options"
puts "-" * 45

begin
  response = client.chat.complete(
    model: "mistral-small-latest",
    messages: [
      { role: "user", content: "Explain quantum computing in simple terms." }
    ],
    temperature: 0.3,
    max_tokens: 200,
    top_p: 0.9,
    stop: [".", "!"],
    presence_penalty: 0.1,
    frequency_penalty: 0.1
  )

  puts "Response: #{response.content}"
  puts "Finish reason: #{response.finish_reason}"
  puts
rescue StandardError => e
  puts "Error: #{e.message}"
  puts
end

# Example 4: Using Message Objects
puts "4. Using Message Objects"
puts "-" * 25

begin
  # Create message objects
  system_msg = MistralAI::Messages::SystemMessage.new(
    content: "You are a knowledgeable science teacher."
  )

  user_msg = MistralAI::Messages::UserMessage.new(
    content: "What is photosynthesis?"
  )

  response = client.chat.complete(
    model: "mistral-small-latest",
    messages: [system_msg, user_msg],
    temperature: 0.5
  )

  puts "Teacher Response: #{response.content}"
  puts
rescue StandardError => e
  puts "Error: #{e.message}"
  puts
end

# Example 5: Streaming Chat Completion
puts "5. Streaming Chat Completion"
puts "-" * 30

begin
  print "Streaming response: "

  client.chat.stream(
    model: "mistral-small-latest",
    messages: [
      { role: "user", content: "Write a short poem about coding." }
    ],
    temperature: 0.8
  ) do |chunk|
    if chunk.content
      print chunk.content
      $stdout.flush
    end
  end

  puts "\n\n"
rescue StandardError => e
  puts "Error: #{e.message}"
  puts
end

# Example 6: Streaming with Enumerable Interface
puts "6. Streaming with Enumerable Interface"
puts "-" * 40

begin
  stream = client.chat.stream(
    model: "mistral-small-latest",
    messages: [
      { role: "user", content: "Count from 1 to 5." }
    ]
  )

  # Collect all chunks
  chunks = stream.to_a
  puts "Received #{chunks.length} chunks"

  # Get content from chunks that have it
  content_chunks = chunks.select(&:content)
  full_content = content_chunks.map(&:content).join
  puts "Full response: #{full_content}"
  puts
rescue StandardError => e
  puts "Error: #{e.message}"
  puts
end

# Example 7: Structured Response Format
puts "7. Structured Response Format (JSON)"
puts "-" * 40

begin
  response = client.chat.complete(
    model: "mistral-small-latest",
    messages: [
      {
        role: "user",
        content: "Generate a JSON object with name, age, and city for a fictional character."
      }
    ],
    response_format: { type: "json_object" },
    temperature: 0.3
  )

  puts "JSON Response: #{response.content}"
  puts
rescue StandardError => e
  puts "Error: #{e.message}"
  puts
end

# Example 8: Error Handling
puts "8. Error Handling Examples"
puts "-" * 28

begin
  # This should fail with invalid content
  client.chat.complete(
    model: "mistral-small-latest",
    messages: [
      { role: "user", content: "" } # Empty content
    ]
  )
rescue ArgumentError => e
  puts "Validation Error: #{e.message}"
rescue MistralAI::APIError => e
  puts "API Error: #{e.message}"
rescue StandardError => e
  puts "Unexpected Error: #{e.message}"
end

puts
puts "=== Phase 2 Examples Complete ==="
