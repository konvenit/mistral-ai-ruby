# frozen_string_literal: true

require_relative "../base_resource"
require_relative "../messages"
require_relative "../responses"
require_relative "../streaming"

module MistralAI
  module Resources
    class Chat < BaseResource
      CHAT_COMPLETION_ENDPOINT = "/v1/chat/completions"

      # Synchronous chat completion
      def complete(model:, messages:, **options)
        # Build and validate messages
        processed_messages = Messages::MessageBuilder.build_messages(messages)
        
        # Prepare request body
        body = {
          model: model,
          messages: processed_messages.map(&:to_h),
          stream: false
        }.merge(filter_chat_options(options))

        # Make the API request
        response_data = post(CHAT_COMPLETION_ENDPOINT, body: body)
        
        # Return structured response
        Responses::ChatResponse.new(response_data)
      rescue => e
        handle_completion_error(e)
      end

      # Streaming chat completion with block
      def stream(model:, messages:, **options, &block)
        # Build and validate messages
        processed_messages = Messages::MessageBuilder.build_messages(messages)
        
        # Prepare request body
        body = {
          model: model,
          messages: processed_messages.map(&:to_h),
          stream: true
        }.merge(filter_chat_options(options))

        if block
          # Stream with callback
          stream_handler = Streaming::StreamHandler.new(http_client)
          stream_handler.stream(path: CHAT_COMPLETION_ENDPOINT, body: body, &block)
        else
          # Return enumerable
          Streaming::StreamEnumerator.new(http_client, path: CHAT_COMPLETION_ENDPOINT, body: body)
        end
      rescue => e
        handle_completion_error(e)
      end

      private

      # Filter and validate chat completion options
      def filter_chat_options(options)
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
          # Convert tool objects to hash format
          if value.is_a?(Array)
            value.map { |tool| tool.respond_to?(:to_h) ? tool.to_h : tool }
          else
            value
          end
        when :tool_choice
          # Validate tool_choice format
          validate_tool_choice(value)
          # Convert ToolChoice object to proper format
          if value.respond_to?(:to_h)
            value.to_h
          else
            value
          end
        when :response_format
          # Validate response_format
          validate_response_format(value)
          # Clean up schema to only include what API accepts
          if value.is_a?(Hash) && value[:schema]
            cleaned_schema = clean_schema_for_api(value[:schema])
            value.merge(schema: cleaned_schema)
          else
            value
          end
        when :stop
          # Ensure stop is an array
          Array(value)
        else
          value
        end
      end

      # Validate tools parameter - enhanced for Phase 4
      def validate_tools(tools)
        return Tools::ToolUtils.validate_tools(tools) if defined?(Tools::ToolUtils)
        
        # Fallback validation for basic compatibility
        unless tools.is_a?(Array)
          raise ArgumentError, "tools must be an array"
        end

        tools.each_with_index do |tool, index|
          case tool
          when Tools::BaseTool
            # Already validated
          when Hash
            # Support both string and symbol keys for flexibility
            type_key = tool["type"] || tool[:type]
            function_key = tool["function"] || tool[:function]
            
            unless type_key && function_key
              raise ArgumentError, "Tool at index #{index} must have 'type' and 'function' keys"
            end

            function = function_key
            unless function.is_a?(Hash) && (function["name"] || function[:name])
              raise ArgumentError, "Invalid function format: must have 'name'"
            end
          else
            raise ArgumentError, "Invalid tool type: #{tool.class}"
          end
        end
      end

      # Validate tool_choice parameter - enhanced for Phase 4
      def validate_tool_choice(tool_choice)
        case tool_choice
        when Tools::ToolChoice
          # Already validated
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

      # Validate response_format parameter - enhanced for Phase 4
      def validate_response_format(response_format)
        unless response_format.is_a?(Hash) && response_format[:type]
          raise ArgumentError, "response_format must be a hash with 'type' key"
        end

        valid_types = ["text", "json_object"]
        unless valid_types.include?(response_format[:type])
          raise ArgumentError, "response_format type must be one of: #{valid_types.join(', ')}"
        end

        # Validate schema if present (Phase 4 feature)
        if response_format[:schema] && defined?(StructuredOutputs::Utils)
          begin
            StructuredOutputs::Utils.validate_data({}, response_format[:schema])
          rescue StructuredOutputs::ValidationError
            # Schema structure validation passed, actual data validation will happen later
          rescue => e
            raise ArgumentError, "Invalid response_format schema: #{e.message}"
          end
        end
      end

      # Handle errors specific to chat completion
      def handle_completion_error(error)
        case error
        when ArgumentError
          raise error
        when MistralAI::APIError
          raise error
        else
          raise MistralAI::APIError, "Chat completion failed: #{error.message}"
        end
      end

      # Clean schema to only include properties that API accepts
      def clean_schema_for_api(schema)
        return schema unless schema.is_a?(Hash)
        
        # Remove properties that Mistral API doesn't accept in schema
        allowed_keys = [:type, :properties, :required, :items, :enum, :minimum, :maximum, :pattern]
        cleaned = {}
        
        schema.each do |key, value|
          key_sym = key.to_sym
          if allowed_keys.include?(key_sym)
            if key_sym == :properties && value.is_a?(Hash)
              # Recursively clean nested properties
              cleaned[key] = value.transform_values { |prop| clean_schema_for_api(prop) }
            else
              cleaned[key] = value
            end
          end
        end
        
        cleaned
      end
    end
  end
end
