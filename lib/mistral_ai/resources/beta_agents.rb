# frozen_string_literal: true

require_relative "../base_resource"
require_relative "../responses"

module MistralAI
  module Resources
    class BetaAgents < BaseResource
      AGENTS_ENDPOINT = "/v1/agents"

      # Create a new agent
      def create(model:, name:, instructions: nil, tools: nil, description: nil, **options)
        # Validate required parameters
        raise ArgumentError, "model is required" if model.nil? || model.empty?
        raise ArgumentError, "name is required" if name.nil? || name.empty?

        # Prepare request body
        body = {
          model: model,
          name: name
        }

        body[:instructions] = instructions if instructions
        body[:description] = description if description
        body[:tools] = validate_and_format_tools(tools) if tools
        
        # Add any additional options
        filtered_options = filter_agent_options(options)
        body.merge!(filtered_options)

        # Make the API request
        response_data = post(AGENTS_ENDPOINT, body: body)
        
        # Return agent response
        Responses::Agent.new(response_data)
      rescue => e
        handle_agent_error(e)
      end

      # List agents
      def list(page: 0, page_size: 20)
        params = {
          page: page,
          page_size: page_size
        }

        response_data = get(AGENTS_ENDPOINT, params: params)
        
        # Return array of agents
        if response_data.is_a?(Array)
          response_data.map { |agent_data| Responses::Agent.new(agent_data) }
        else
          # Handle paginated response if needed
          agents_data = response_data.dig("data") || response_data.dig("agents") || []
          agents_data.map { |agent_data| Responses::Agent.new(agent_data) }
        end
      rescue => e
        handle_agent_error(e)
      end

      # Get a specific agent (renamed to avoid conflict with inherited get method)
      def retrieve(agent_id:)
        validate_agent_id(agent_id)
        
        path = "#{AGENTS_ENDPOINT}/#{agent_id}"
        response_data = get(path)
        
        Responses::Agent.new(response_data)
      rescue => e
        handle_agent_error(e)
      end

      # Delete an agent
      def delete(agent_id:)
        validate_agent_id(agent_id)
        
        path = "#{AGENTS_ENDPOINT}/#{agent_id}"
        
        # Make DELETE request
        begin
          response = http_client.delete(path)
          { success: true, message: "Agent deleted successfully" }
        rescue => e
          handle_agent_error(e)
        end
      end

      private

      # Validate agent_id parameter
      def validate_agent_id(agent_id)
        unless agent_id.is_a?(String)
          raise ArgumentError, "agent_id must be a string"
        end
        
        if agent_id.empty?
          raise ArgumentError, "agent_id is required and cannot be empty"
        end
      end

      # Validate and format tools for agent creation
      def validate_and_format_tools(tools)
        unless tools.is_a?(Array)
          raise ArgumentError, "tools must be an array"
        end

        tools.each do |tool|
          case tool
          when Hash
            validate_tool_hash(tool)
          when String
            # Handle simple tool names like "web_search", "code_interpreter"
            validate_simple_tool(tool)
          else
            raise ArgumentError, "Each tool must be a hash or string"
          end
        end

        # Format tools for API
        tools.map do |tool|
          case tool
          when Hash
            tool
          when String
            { type: tool }
          end
        end
      end

      # Validate tool hash format
      def validate_tool_hash(tool)
        unless tool[:type] || tool["type"]
          raise ArgumentError, "Tool must have a 'type' field"
        end

        tool_type = tool[:type] || tool["type"]
        valid_types = ["function", "web_search", "web_search_premium", "code_interpreter", "image_generation", "document_library"]
        
        unless valid_types.include?(tool_type)
          raise ArgumentError, "Invalid tool type: #{tool_type}. Valid types: #{valid_types.join(', ')}"
        end

        # If it's a function tool, validate the function structure
        if tool_type == "function"
          function = tool[:function] || tool["function"]
          unless function && function.is_a?(Hash) && (function[:name] || function["name"])
            raise ArgumentError, "Function tool must have a 'function' object with 'name'"
          end
        end
      end

      # Validate simple tool names
      def validate_simple_tool(tool)
        valid_simple_tools = ["web_search", "web_search_premium", "code_interpreter", "image_generation", "document_library"]
        unless valid_simple_tools.include?(tool)
          raise ArgumentError, "Invalid simple tool: #{tool}. Valid tools: #{valid_simple_tools.join(', ')}"
        end
      end

      # Filter and validate agent creation options
      def filter_agent_options(options)
        allowed_options = {
          completion_args: :completion_args,
          handoffs: :handoffs
        }

        filtered = {}
        
        allowed_options.each do |option_key, api_key|
          if options.key?(option_key)
            value = options[option_key]
            filtered[api_key] = value
          end
        end

        filtered
      end

      # Handle errors specific to agent management
      def handle_agent_error(error)
        case error
        when ArgumentError
          raise error
        when MistralAI::APIError
          raise error
        else
          raise MistralAI::APIError, "Agent operation failed: #{error.message}"
        end
      end
    end
  end
end 