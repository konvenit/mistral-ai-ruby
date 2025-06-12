#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/mistral_ai"

# Demo: Programmatic console chat usage
# This shows how to use the console chat functionality programmatically

puts "🎭 Console Chat Demo"
puts "=" * 40

# Example of how someone might integrate the chat functionality
# into their own applications or scripts

class SimpleChatDemo
  def initialize(api_key)
    @client = MistralAI::Client.new(api_key: api_key)
    @messages = []
  end

  def send_message(content)
    # Add user message
    @messages << { role: "user", content: content }
    
    puts "💬 User: #{content}"
    print "🤖 Assistant: "
    
    response_content = ""
    
    # Stream the response
    @client.chat.stream(
      model: "mistral-small-latest",
      messages: @messages,
      temperature: 0.7
    ) do |chunk|
      if chunk.content
        print chunk.content
        $stdout.flush
        response_content += chunk.content
      end
    end
    
    puts "\n"
    
    # Add assistant response to conversation
    @messages << { role: "assistant", content: response_content }
    
    response_content
  rescue => e
    puts "\n❌ Error: #{e.message}"
    # Remove failed user message
    @messages.pop
    nil
  end

  def conversation_history
    @messages
  end

  def clear_history
    @messages.clear
  end
end

# Demo usage
if ENV["MISTRAL_API_KEY"] || ARGV[0]
  api_key = ENV["MISTRAL_API_KEY"] || ARGV[0]
  
  puts "Using API key: #{api_key[0..7]}..." if api_key
  puts

  demo = SimpleChatDemo.new(api_key)
  
  # Simulate a conversation
  demo.send_message("Hello! Can you introduce yourself?")
  
  puts
  demo.send_message("What's 2 + 2?")
  
  puts
  demo.send_message("Can you write a haiku about coding?")
  
  puts
  puts "💾 Conversation History:"
  puts "-" * 25
  demo.conversation_history.each_with_index do |msg, i|
    role_emoji = msg[:role] == "user" ? "💬" : "🤖"
    puts "#{i + 1}. #{role_emoji} #{msg[:role].capitalize}: #{msg[:content][0..100]}#{'...' if msg[:content].length > 100}"
  end
  
else
  puts "❌ Please provide an API key as argument or set MISTRAL_API_KEY environment variable"
  puts
  puts "Usage:"
  puts "  ruby examples/console_demo.rb your-api-key"
  puts "  MISTRAL_API_KEY=your-key ruby examples/console_demo.rb"
  puts
  puts "For interactive chat, use:"
  puts "  ./bin/mistral-chat --api-key your-api-key"
end 