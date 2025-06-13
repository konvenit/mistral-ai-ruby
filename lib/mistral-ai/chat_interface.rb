# frozen_string_literal: true

require "io/console"
require "json"
require "yaml"

module MistralAI
  # Console Chat Interface for Mistral AI Ruby Client
  class ChatInterface
    attr_reader :api_key, :model, :mcp_mode, :mcp_servers, :mcp_settings, :system_prompt

    def initialize(api_key:, model: "mistral-small-latest", mcp_mode: false, 
                   mcp_servers: [], mcp_settings: nil, system_prompt: nil)
      @api_key = api_key
      @model = model
      @messages = []
      @client = nil
      @mcp_mode = mcp_mode
      @mcp_servers = mcp_servers
      @mcp_settings = mcp_settings
      @system_prompt = system_prompt
      setup_client
      setup_initial_system_message
    end

    def start
      print_welcome
      setup_signal_handling
      chat_loop
    rescue Interrupt
      puts "\n\n👋 Goodbye!"
      exit(0)
    end

    private

    def setup_client
      MistralAI.configure do |config|
        config.api_key = @api_key
      end
      @client = MistralAI.client
    rescue => e
      puts "❌ Error setting up client: #{e.message}"
      exit(1)
    end

    def setup_initial_system_message
      return unless @system_prompt

      # Add system message as the first message
      @messages << { role: "system", content: @system_prompt }
    end

    def print_welcome
      puts "🤖 Mistral AI Chat Interface"
      puts "=" * 50
      puts "Model: #{@model}"
      puts "Mode: #{@mcp_mode ? 'MCP' : 'Standard'}"
      
      if @mcp_mode && !@mcp_servers.empty?
        puts "MCP Servers: #{@mcp_servers.join(', ')}"
      end
      
      if @mcp_settings
        puts "MCP Settings: Loaded from configuration file"
      end
      
      if @system_prompt
        puts "System Prompt: Loaded from file"
      end
      
      puts "Type 'exit', 'quit', or press Ctrl+C to end the conversation"
      puts "Type 'clear' to clear conversation history"
      puts "Type 'help' for available commands"
      puts "=" * 50
      puts
    end

    def setup_signal_handling
      Signal.trap("INT") do
        puts "\n\n👋 Goodbye!"
        exit(0)
      end
    end

    def chat_loop
      loop do
        print "💬 You: "
        user_input = gets&.chomp

        # Handle nil input (EOF)
        if user_input.nil?
          puts "\n👋 Goodbye!"
          break
        end

        # Handle commands
        case user_input.downcase.strip
        when "exit", "quit"
          puts "👋 Goodbye!"
          break
        when "clear"
          clear_conversation_history
          next
        when "help"
          print_help
          next
        when "status"
          print_status
          next
        when ""
          puts "Please enter a message or command."
          next
        end

        # Add user message to conversation
        add_user_message(user_input)

        # Get AI response with streaming
        print "🤖 Assistant: "
        get_streaming_response
        puts "\n"
      end
    end

    def clear_conversation_history
      # Keep system message if it exists
      system_messages = @messages.select { |msg| msg[:role] == "system" }
      @messages = system_messages
      puts "🧹 Conversation history cleared."
      puts
    end

    def add_user_message(content)
      if @mcp_mode
        @messages << { 
          role: "user", 
          content: content, 
          type: "mcp",
          servers: @mcp_servers,
          settings: @mcp_settings
        }
      else
        @messages << { role: "user", content: content }
      end
    end

    def get_streaming_response
      response_content = ""
      
      begin
        if @mcp_mode
          stream_options = {
            model: @model,
            messages: @messages,
            temperature: 0.7,
            max_tokens: 1000,
            mcp: true
          }
          
          # Add MCP-specific options if available
          stream_options[:mcp_servers] = @mcp_servers unless @mcp_servers.empty?
          stream_options[:mcp_settings] = @mcp_settings if @mcp_settings
          
          @client.chat.stream(stream_options) do |chunk|
            if chunk.content
              print chunk.content
              $stdout.flush
              response_content += chunk.content
            end
          end
        else
          @client.chat.stream(
            model: @model,
            messages: @messages,
            temperature: 0.7,
            max_tokens: 1000
          ) do |chunk|
            if chunk.content
              print chunk.content
              $stdout.flush
              response_content += chunk.content
            end
          end
        end

        # Add assistant response to conversation history
        add_assistant_message(response_content)

      rescue MistralAI::RateLimitError => e
        puts "\n⚠️  Rate limit exceeded. Please wait a moment and try again."
        puts "Error: #{e.message}"
        # Remove the user message since we couldn't process it
        @messages.pop
      rescue MistralAI::AuthenticationError => e
        puts "\n❌ Authentication failed. Please check your API key."
        puts "Error: #{e.message}"
        exit(1)
      rescue MistralAI::APIError => e
        puts "\n❌ API error occurred:"
        puts "Error: #{e.message}"
        # Remove the user message since we couldn't process it
        @messages.pop
      rescue => e
        puts "\n❌ Unexpected error occurred:"
        puts "Error: #{e.message}"
        # Remove the user message since we couldn't process it
        @messages.pop
      end
    end

    def add_assistant_message(content)
      if @mcp_mode
        @messages << { 
          role: "assistant", 
          content: content, 
          type: "mcp",
          servers: @mcp_servers,
          settings: @mcp_settings
        }
      else
        @messages << { role: "assistant", content: content }
      end
    end

    def print_status
      puts
      puts "📊 Current Status:"
      puts "  Model: #{@model}"
      puts "  Mode: #{@mcp_mode ? 'MCP' : 'Standard'}"
      puts "  Messages in history: #{@messages.length}"
      puts "  System prompt: #{@system_prompt ? 'Loaded' : 'None'}"
      
      if @mcp_mode
        puts "  MCP Servers: #{@mcp_servers.empty? ? 'None' : @mcp_servers.join(', ')}"
        puts "  MCP Settings: #{@mcp_settings ? 'Loaded' : 'None'}"
      end
      puts
    end

    def print_help
      puts
      puts "📖 Available Commands:"
      puts "  exit, quit  - End the conversation"
      puts "  clear       - Clear conversation history (keeps system prompt)"
      puts "  help        - Show this help message"
      puts "  status      - Show current configuration status"
      puts
      puts "💡 Tips:"
      puts "  - Your conversation history is maintained across messages"
      puts "  - Responses are streamed in real-time"
      puts "  - Press Ctrl+C to exit at any time"
      
      if @system_prompt
        puts "  - System prompt is active and will guide the assistant's behavior"
      end
      
      if @mcp_mode
        puts "  - You are in MCP mode - enhanced capabilities may be available"
        unless @mcp_servers.empty?
          puts "  - Active MCP servers: #{@mcp_servers.join(', ')}"
        end
      end
      puts
    end
  end
end 