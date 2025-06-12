# frozen_string_literal: true

require_relative "../base_resource"
require_relative "../messages"
require_relative "../responses"
require_relative "../streaming"

module MistralAI
  module Resources
    class Agents < BaseResource
      AGENT_COMPLETION_ENDPOINT = "/v1/agents/completions"

      # Synchronous agent completion
      def complete(agent_id:, messages:, **options)
        # Validate agent_id
        validate_agent_id(agent_id)
        
        # Build and validate messages
        processed_messages = Messages::MessageBuilder.build_messages(messages)
        
        # Prepare request body
        body = {
          agent_id: agent_id,
          messages: processed_messages.map(&:to_h),
          stream: false
        }.merge(filter_agent_options(options))

        # Make the API request
        response_data = post(AGENT_COMPLETION_ENDPOINT, body: body)
        
        # Return structured response
        Responses::ChatResponse.new(response_data)
      rescue => e
        handle_completion_error(e)
      end

      # Streaming agent completion with block
      def stream(agent_id:, messages:, **options, &block)
        # Validate agent_id
        validate_agent_id(agent_id)
        
        # Build and validate messages
        processed_messages = Messages::MessageBuilder.build_messages(messages)
        
        # Prepare request body
        body = {
          agent_id: agent_id,
          messages: processed_messages.map(&:to_h),
          stream: true
        }.merge(filter_agent_options(options))

        if block
          # Stream with callback
          stream_handler = Streaming::StreamHandler.new(http_client)
          stream_handler.stream(path: AGENT_COMPLETION_ENDPOINT, body: body, &block)
        else
          # Return enumerable
          Streaming::StreamEnumerator.new(http_client, path: AGENT_COMPLETION_ENDPOINT, body: body)
        end
      rescue => e
        handle_completion_error(e)
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

      # Filter and validate agent completion options
      def filter_agent_options(options)
        allowed_options = {
          temperature: :temperature,
          top_p: :top_p,
          max_tokens: :max_tokens,
          min_tokens: :min_tokens,
          stop: :stop,
          random_seed: :random_seed,
          response_format: :response_format,
          tools: :tools,
          tool_choice: :tool_choice,
          presence_penalty: :presence_penalty,
          frequency_penalty: :frequency_penalty,
          n: :n
        }

        filtered = {}
        
        allowed_options.each do |option_key, api_key|
          if options.key?(option_key)
            value = options[option_key]
            filtered[api_key] = transform_option_value(option_key, value)
          end
        end

        filtered
      end

      # Transform option values for API compatibility
      def transform_option_value(option_key, value)
        case option_key
        when :tools
          # Validate tools format
          validate_tools(value)
          value
        when :tool_choice
          # Validate tool_choice format
          validate_tool_choice(value)
          value
        when :response_format
          # Validate response_format
          validate_response_format(value)
          value
        when :stop
          # Ensure stop is an array
          Array(value)
        else
          value
        end
      end

      # Validate tools parameter
      def validate_tools(tools)
        unless tools.is_a?(Array)
          raise ArgumentError, "tools must be an array"
        end

        tools.each do |tool|
          unless tool.is_a?(Hash) && tool[:type] && tool[:function]
            raise ArgumentError, "Invalid tool format: each tool must have 'type' and 'function'"
          end

          function = tool[:function]
          unless function.is_a?(Hash) && function[:name]
            raise ArgumentError, "Invalid function format: must have 'name'"
          end
        end
      end

      # Validate tool_choice parameter
      def validate_tool_choice(tool_choice)
        case tool_choice
        when "auto", "none"
          # Valid string values
        when Hash
          unless tool_choice[:type] && tool_choice[:function] && tool_choice[:function][:name]
            raise ArgumentError, "Invalid tool_choice format"
          end
        else
          raise ArgumentError, "tool_choice must be 'auto', 'none', or a specific tool object"
        end
      end

      # Validate response_format parameter
      def validate_response_format(response_format)
        unless response_format.is_a?(Hash) && response_format[:type]
          raise ArgumentError, "response_format must be a hash with 'type' key"
        end

        valid_types = ["text", "json_object"]
        unless valid_types.include?(response_format[:type])
          raise ArgumentError, "response_format type must be one of: #{valid_types.join(', ')}"
        end
      end

      # Handle errors specific to agent completion
      def handle_completion_error(error)
        case error
        when ArgumentError
          raise error
        when MistralAI::APIError
          raise error
        else
          raise MistralAI::APIError, "Agent completion failed: #{error.message}"
        end
      end
    end
  end
end
