# frozen_string_literal: true

module MistralAI
  module Messages
    # Base class for all message types
    class BaseMessage
      attr_reader :role, :content

      def initialize(content:)
        @content = content
        validate_content!
      end

      def to_h
        {
          role: role,
          content: content
        }
      end

      def to_json(*args)
        to_h.to_json(*args)
      end

      private

      def validate_content!
        raise ArgumentError, "Content cannot be nil or empty" if content.nil? || content.strip.empty?
      end
    end

    # User message for chat completions
    class UserMessage < BaseMessage
      def initialize(content:)
        @role = "user"
        super
      end
    end

    # System message for chat completions
    class SystemMessage < BaseMessage
      def initialize(content:)
        @role = "system"
        super
      end
    end

    # Assistant message for chat completions
    class AssistantMessage < BaseMessage
      attr_reader :tool_calls

      def initialize(content: nil, tool_calls: nil)
        @role = "assistant"
        @tool_calls = tool_calls

        # Assistant messages can have either content or tool_calls, but not both nil
        if content.nil? && (tool_calls.nil? || tool_calls.empty?)
          raise ArgumentError, "Assistant message must have either content or tool_calls"
        end

        @content = content
        validate_tool_calls! if tool_calls
      end

      def to_h
        hash = { role: role }
        hash[:content] = content if content
        hash[:tool_calls] = tool_calls if tool_calls && !tool_calls.empty?
        hash
      end

      private

      def validate_tool_calls!
        raise ArgumentError, "tool_calls must be an array" unless tool_calls.is_a?(Array)

        tool_calls.each do |tool_call|
          unless tool_call.is_a?(Hash) && tool_call[:id] && tool_call[:type] && tool_call[:function]
            raise ArgumentError, "Invalid tool_call format"
          end
        end
      end

      def validate_content!
        # Override to allow nil content for assistant messages with tool calls
        return if content.nil? && tool_calls && !tool_calls.empty?

        super
      end
    end

    # Tool message for function call responses
    class ToolMessage
      attr_reader :role, :content, :tool_call_id

      def initialize(content:, tool_call_id:)
        @role = "tool"
        @content = content
        @tool_call_id = tool_call_id
        validate!
      end

      def to_h
        {
          role: role,
          content: content,
          tool_call_id: tool_call_id
        }
      end

      def to_json(*args)
        to_h.to_json(*args)
      end

      private

      def validate!
        raise ArgumentError, "Content cannot be nil or empty" if content.nil? || content.strip.empty?
        raise ArgumentError, "tool_call_id cannot be nil or empty" if tool_call_id.nil? || tool_call_id.strip.empty?
      end
    end

    # Utility class for message creation and validation
    class MessageBuilder
      # Convert various message formats to proper message objects
      def self.build(message)
        case message
        when Hash
          build_from_hash(message)
        when BaseMessage, ToolMessage
          message
        else
          raise ArgumentError, "Invalid message format: #{message.class}"
        end
      end

      # Build messages from an array of various formats
      def self.build_messages(messages)
        # Handle single message (not in array)
        messages = [messages] unless messages.is_a?(Array)
        messages.map { |message| build(message) }
      end

      def self.build_from_hash(hash)
        role = hash[:role] || hash["role"]
        content = hash[:content] || hash["content"]

        case role
        when "user"
          UserMessage.new(content: content)
        when "system"
          SystemMessage.new(content: content)
        when "assistant"
          tool_calls = hash[:tool_calls] || hash["tool_calls"]
          AssistantMessage.new(content: content, tool_calls: tool_calls)
        when "tool"
          tool_call_id = hash[:tool_call_id] || hash["tool_call_id"]
          ToolMessage.new(content: content, tool_call_id: tool_call_id)
        else
          raise ArgumentError, "Unknown message role: #{role}"
        end
      end
    end
  end
end
