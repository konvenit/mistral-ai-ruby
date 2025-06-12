# frozen_string_literal: true

module MistralAI
  module Responses
    # Response object for chat completion usage statistics
    class Usage
      attr_reader :prompt_tokens, :completion_tokens, :total_tokens

      def initialize(data)
        @prompt_tokens = data["prompt_tokens"] || data[:prompt_tokens]
        @completion_tokens = data["completion_tokens"] || data[:completion_tokens]  
        @total_tokens = data["total_tokens"] || data[:total_tokens]
      end

      def to_h
        {
          prompt_tokens: prompt_tokens,
          completion_tokens: completion_tokens,
          total_tokens: total_tokens
        }
      end
    end

    # Message object within chat completion response
    class Message
      attr_reader :role, :content, :tool_calls

      def initialize(data)
        @role = data["role"] || data[:role]
        @content = data["content"] || data[:content]
        @tool_calls = parse_tool_calls(data["tool_calls"] || data[:tool_calls])
      end

      def to_h
        hash = { role: role }
        hash[:content] = content if content
        hash[:tool_calls] = tool_calls if tool_calls && !tool_calls.empty?
        hash
      end

      private

      def parse_tool_calls(tool_calls_data)
        return nil if tool_calls_data.nil? || tool_calls_data.empty?
        
        Array(tool_calls_data).map do |tool_call|
          {
            id: tool_call["id"] || tool_call[:id],
            type: tool_call["type"] || tool_call[:type] || "function",
            function: parse_function(tool_call["function"] || tool_call[:function])
          }
        end
      end

      def parse_function(function_data)
        return nil unless function_data
        
        function_hash = {
          name: function_data["name"] || function_data[:name]
        }
        
        # Only include arguments if they exist
        arguments = function_data["arguments"] || function_data[:arguments]
        function_hash[:arguments] = arguments if arguments
        
        function_hash
      end
    end

    # Delta object for streaming responses
    class Delta
      attr_reader :role, :content, :tool_calls

      def initialize(data)
        @role = data["role"] || data[:role]
        @content = data["content"] || data[:content]
        @tool_calls = parse_tool_calls(data["tool_calls"] || data[:tool_calls])
      end

      def to_h
        hash = {}
        hash[:role] = role if role
        hash[:content] = content if content
        hash[:tool_calls] = tool_calls if tool_calls && !tool_calls.empty?
        hash
      end

      private

      def parse_tool_calls(tool_calls_data)
        return nil if tool_calls_data.nil? || tool_calls_data.empty?
        
        Array(tool_calls_data).map do |tool_call|
          hash = {}
          hash[:id] = tool_call["id"] || tool_call[:id] if tool_call["id"] || tool_call[:id]
          hash[:type] = tool_call["type"] || tool_call[:type] || "function"
          
          function_data = tool_call["function"] || tool_call[:function]
          if function_data
            function_hash = {}
            function_hash[:name] = function_data["name"] || function_data[:name] if function_data["name"] || function_data[:name]
            function_hash[:arguments] = function_data["arguments"] || function_data[:arguments] if function_data["arguments"] || function_data[:arguments]
            hash[:function] = function_hash unless function_hash.empty?
          end
          
          hash
        end
      end
    end

    # Choice object within chat completion response
    class Choice
      attr_reader :index, :message, :finish_reason

      def initialize(data)
        @index = data["index"] || data[:index]
        @message = Message.new(data["message"] || data[:message]) if data["message"] || data[:message]
        @finish_reason = data["finish_reason"] || data[:finish_reason]
      end

      def to_h
        {
          index: index,
          message: message&.to_h,
          finish_reason: finish_reason
        }
      end
    end

    # Choice object for streaming responses
    class StreamChoice
      attr_reader :index, :delta, :finish_reason

      def initialize(data)
        @index = data["index"] || data[:index]
        @delta = Delta.new(data["delta"] || data[:delta]) if data["delta"] || data[:delta]
        @finish_reason = data["finish_reason"] || data[:finish_reason]
      end

      def to_h
        {
          index: index,
          delta: delta&.to_h,
          finish_reason: finish_reason
        }
      end
    end

    # Main chat completion response object
    class ChatResponse
      attr_reader :id, :object, :created, :model, :choices, :usage

      def initialize(data)
        @id = data["id"] || data[:id]
        @object = data["object"] || data[:object]
        @created = data["created"] || data[:created]
        @model = data["model"] || data[:model]
        @choices = parse_choices(data["choices"] || data[:choices])
        @usage = Usage.new(data["usage"] || data[:usage]) if data["usage"] || data[:usage]
      end

      def to_h
        {
          id: id,
          object: object,
          created: created,
          model: model,
          choices: choices&.map(&:to_h),
          usage: usage&.to_h
        }
      end

      # Convenience method to get the first choice message content
      def content
        choices&.first&.message&.content
      end

      # Convenience method to get the first choice message
      def message
        choices&.first&.message
      end

      # Convenience method to get the finish reason
      def finish_reason
        choices&.first&.finish_reason
      end

      # Phase 4: Tool calling support
      # Check if response contains tool calls
      def has_tool_calls?
        !!(message&.tool_calls && !message.tool_calls.empty?)
      end

      # Get tool calls from the response
      def tool_calls
        message&.tool_calls || []
      end

      # Extract tool calls as ToolCall objects (Phase 4 feature)
      def extract_tool_calls
        return [] unless defined?(Tools::ToolUtils)
        Tools::ToolUtils.extract_tool_calls(self)
      end

      # Phase 4: Structured outputs support
      # Parse response content as structured object
      def structured_content(schema_class = nil)
        content_text = content
        return nil unless content_text

        if defined?(MistralAI::StructuredOutputs::ObjectMapper)
          begin
            MistralAI::StructuredOutputs::ObjectMapper.map(content_text, schema_class)
          rescue MistralAI::StructuredOutputs::ValidationError
            # Return content as-is if JSON parsing fails
            content_text
          end
        else
          # Fallback to basic JSON parsing if StructuredOutputs not available
          begin
            JSON.parse(content_text)
          rescue JSON::ParserError
            content_text
          end
        end
      end

      # Validate response against schema
      def validate_schema(schema)
        return false unless content && defined?(StructuredOutputs::Utils)
        
        begin
          StructuredOutputs::Utils.validate_json(content, schema)
          true
        rescue StructuredOutputs::ValidationError
          false
        end
      end

      private

      def parse_choices(choices_data)
        return nil unless choices_data
        
        Array(choices_data).map { |choice_data| Choice.new(choice_data) }
      end
    end

    # Streaming chat completion response object
    class ChatStreamResponse
      attr_reader :id, :object, :created, :model, :choices

      def initialize(data)
        @id = data["id"] || data[:id]
        @object = data["object"] || data[:object]
        @created = data["created"] || data[:created]
        @model = data["model"] || data[:model]
        @choices = parse_stream_choices(data["choices"] || data[:choices])
      end

      def to_h
        {
          id: id,
          object: object,
          created: created,
          model: model,
          choices: choices&.map(&:to_h)
        }
      end

      # Convenience method to get the first choice delta content
      def content
        choices&.first&.delta&.content
      end

      # Convenience method to get the first choice delta
      def delta
        choices&.first&.delta
      end

      # Convenience method to get the finish reason
      def finish_reason
        choices&.first&.finish_reason
      end

      private

      def parse_stream_choices(choices_data)
        return nil unless choices_data
        
        Array(choices_data).map { |choice_data| StreamChoice.new(choice_data) }
      end
    end

    # Agent response for agent management operations
    class Agent
      attr_reader :id, :name, :model, :version, :created_at, :updated_at, 
                  :instructions, :tools, :description, :completion_args, :handoffs, :object

      def initialize(data)
        @id = data["id"] || data[:id]
        @name = data["name"] || data[:name]
        @model = data["model"] || data[:model]
        @version = data["version"] || data[:version]
        @created_at = data["created_at"] || data[:created_at]
        @updated_at = data["updated_at"] || data[:updated_at]
        @instructions = data["instructions"] || data[:instructions]
        @tools = data["tools"] || data[:tools]
        @description = data["description"] || data[:description]
        @completion_args = data["completion_args"] || data[:completion_args]
        @handoffs = data["handoffs"] || data[:handoffs]
        @object = data["object"] || data[:object] || "agent"
      end

      def to_h
        {
          id: @id,
          name: @name,
          model: @model,
          version: @version,
          created_at: @created_at,
          updated_at: @updated_at,
          instructions: @instructions,
          tools: @tools,
          description: @description,
          completion_args: @completion_args,
          handoffs: @handoffs,
          object: @object
        }.compact
      end
    end
  end
end
