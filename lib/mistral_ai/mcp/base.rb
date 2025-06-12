# frozen_string_literal: true

require "json"
require "logger"
require_relative "exceptions"

module MistralAI
  module MCP
    # System prompt structure returned by MCP prompts
    class MCPSystemPrompt
      attr_accessor :description, :messages

      def initialize(description: nil, messages: [])
        @description = description
        @messages = messages
      end

      def to_h
        {
          description: @description,
          messages: @messages
        }
      end
    end

    # Base class for MCP clients that provides common functionality
    # This is similar to the Python MCPClientProtocol and MCPClientBase
    class MCPClientBase
      attr_reader :name, :session, :initialized

      def initialize(name: nil)
        @name = name || self.class.name
        @session = nil
        @initialized = false
        @logger = Logger.new($stdout)
        @logger.level = Logger::WARN
      end

      # Initialize the MCP session - must be implemented by subclasses
      def initialize_session
        raise NotImplementedError, "Subclasses must implement initialize_session"
      end

      # Close the MCP session - must be implemented by subclasses  
      def close
        raise NotImplementedError, "Subclasses must implement close"
      end

      # Get transport for MCP communication - must be implemented by subclasses
      def get_transport
        raise NotImplementedError, "Subclasses must implement get_transport"
      end

      # Convert MCP content to Mistral format
      def convert_content(mcp_content)
        # Only supporting text tool responses for now
        unless mcp_content.is_a?(Hash) && mcp_content["type"] == "text"
          raise MCPException, "Only supporting text tool responses for now."
        end
        
        {
          "type" => "text",
          "text" => mcp_content["text"]
        }
      end

      # Convert list of MCP contents to Mistral format
      def convert_content_list(mcp_contents)
        content_chunks = []
        mcp_contents.each do |mcp_content|
          content_chunks << convert_content(mcp_content)
        end
        content_chunks
      end

      # Get available tools from MCP server
      def get_tools
        ensure_initialized
        
        begin
          response = call_rpc_method("tools/list")
          tools = []
          
          response["tools"]&.each do |mcp_tool|
            # Clean up the schema for Mistral API compatibility
            parameters = clean_schema_for_mistral(mcp_tool["inputSchema"])
            
            tools << {
              "type" => "function",
              "function" => {
                "name" => mcp_tool["name"],
                "description" => mcp_tool["description"],
                "parameters" => parameters,
                "strict" => true
              }
            }
          end
          
          tools
        rescue => e
          @logger.error "Error getting tools: #{e.message}"
          raise MCPException, "Failed to get tools: #{e.message}"
        end
      end

      # Execute a tool with given arguments
      def execute_tool(name, arguments = {})
        ensure_initialized
        
        begin
          response = call_rpc_method("tools/call", {
            "name" => name,
            "arguments" => arguments
          })
          
          content = response["content"] || []
          convert_content_list(content)
        rescue => e
          @logger.error "Error executing tool #{name}: #{e.message}"
          raise MCPException, "Failed to execute tool #{name}: #{e.message}"
        end
      end

      # Get system prompt by name with arguments
      def get_system_prompt(name, arguments = {})
        ensure_initialized
        
        begin
          response = call_rpc_method("prompts/get", {
            "name" => name,
            "arguments" => arguments
          })
          
          messages = response["messages"]&.map do |message|
            {
              "role" => message["role"],
              "content" => convert_content(message["content"])
            }
          end || []
          
          MCPSystemPrompt.new(
            description: response["description"],
            messages: messages
          )
        rescue => e
          @logger.error "Error getting system prompt #{name}: #{e.message}"
          raise MCPException, "Failed to get system prompt #{name}: #{e.message}"
        end
      end

      # List available system prompts
      def list_system_prompts
        ensure_initialized
        
        begin
          call_rpc_method("prompts/list")
        rescue => e
          @logger.error "Error listing system prompts: #{e.message}"
          raise MCPException, "Failed to list system prompts: #{e.message}"
        end
      end

      # Check if the client is initialized
      def initialized?
        @initialized
      end

      def to_s
        "#{self.class.name}(name=#{@name})"
      end

      def inspect
        "<#{self.class.name} name=#{@name.inspect} id=0x#{object_id.to_s(16)}>"
      end

      private

      # Ensure the client is initialized
      def ensure_initialized
        unless @initialized
          initialize_session
          @initialized = true
        end
      end

      # Call an RPC method - must be implemented by subclasses
      def call_rpc_method(method, params = {})
        raise NotImplementedError, "Subclasses must implement call_rpc_method"
      end

      # Clean up JSON schema for Mistral API compatibility
      def clean_schema_for_mistral(schema)
        return nil unless schema.is_a?(Hash)

        cleaned = schema.dup
        
        # Remove MCP-specific schema fields that Mistral doesn't understand
        cleaned.delete("$schema")
        cleaned.delete("additionalProperties") if cleaned["additionalProperties"] != false
        
        # Ensure additionalProperties is false for object types (Mistral requirement)
        if cleaned["type"] == "object"
          cleaned["additionalProperties"] = false
        end
        
        # Recursively clean nested objects and arrays
        if cleaned["properties"].is_a?(Hash)
          cleaned["properties"] = cleaned["properties"].transform_values do |prop_schema|
            clean_schema_for_mistral(prop_schema)
          end
        end
        
        if cleaned["items"].is_a?(Hash)
          cleaned["items"] = clean_schema_for_mistral(cleaned["items"])
        end
        
        cleaned
      end
    end
  end
end 