# frozen_string_literal: true

RSpec.describe MistralAI::Messages do
  describe MistralAI::Messages::UserMessage do
    describe "#initialize" do
      it "creates a user message with content" do
        message = described_class.new(content: "Hello, world!")

        expect(message.role).to eq("user")
        expect(message.content).to eq("Hello, world!")
      end

      it "raises an error for nil content" do
        expect do
          described_class.new(content: nil)
        end.to raise_error(ArgumentError, "Content cannot be nil or empty")
      end

      it "raises an error for empty content" do
        expect do
          described_class.new(content: "")
        end.to raise_error(ArgumentError, "Content cannot be nil or empty")
      end

      it "raises an error for whitespace-only content" do
        expect do
          described_class.new(content: "   ")
        end.to raise_error(ArgumentError, "Content cannot be nil or empty")
      end
    end

    describe "#to_h" do
      it "returns a hash representation" do
        message = described_class.new(content: "Test message")

        expect(message.to_h).to eq({
                                     role: "user",
                                     content: "Test message"
                                   })
      end
    end

    describe "#to_json" do
      it "returns JSON representation" do
        message = described_class.new(content: "Test message")

        json = JSON.parse(message.to_json)
        expect(json).to eq({
                             "role" => "user",
                             "content" => "Test message"
                           })
      end
    end
  end

  describe MistralAI::Messages::SystemMessage do
    describe "#initialize" do
      it "creates a system message with content" do
        message = described_class.new(content: "You are a helpful assistant.")

        expect(message.role).to eq("system")
        expect(message.content).to eq("You are a helpful assistant.")
      end

      it "raises an error for invalid content" do
        expect do
          described_class.new(content: nil)
        end.to raise_error(ArgumentError, "Content cannot be nil or empty")
      end
    end

    describe "#to_h" do
      it "returns a hash representation" do
        message = described_class.new(content: "System prompt")

        expect(message.to_h).to eq({
                                     role: "system",
                                     content: "System prompt"
                                   })
      end
    end
  end

  describe MistralAI::Messages::AssistantMessage do
    describe "#initialize" do
      it "creates an assistant message with content" do
        message = described_class.new(content: "Hello! How can I help you?")

        expect(message.role).to eq("assistant")
        expect(message.content).to eq("Hello! How can I help you?")
        expect(message.tool_calls).to be_nil
      end

      it "creates an assistant message with tool calls" do
        tool_calls = [
          {
            id: "call_123",
            type: "function",
            function: { name: "get_weather", arguments: '{"location": "Paris"}' }
          }
        ]

        message = described_class.new(tool_calls: tool_calls)

        expect(message.role).to eq("assistant")
        expect(message.content).to be_nil
        expect(message.tool_calls).to eq(tool_calls)
      end

      it "creates an assistant message with both content and tool calls" do
        tool_calls = [
          {
            id: "call_123",
            type: "function",
            function: { name: "get_weather", arguments: '{"location": "Paris"}' }
          }
        ]

        message = described_class.new(
          content: "I'll check the weather for you.",
          tool_calls: tool_calls
        )

        expect(message.role).to eq("assistant")
        expect(message.content).to eq("I'll check the weather for you.")
        expect(message.tool_calls).to eq(tool_calls)
      end

      it "raises an error when both content and tool_calls are nil" do
        expect do
          described_class.new
        end.to raise_error(ArgumentError, "Assistant message must have either content or tool_calls")
      end

      it "raises an error when both content and tool_calls are empty" do
        expect do
          described_class.new(content: nil, tool_calls: [])
        end.to raise_error(ArgumentError, "Assistant message must have either content or tool_calls")
      end

      it "raises an error for invalid tool_calls format" do
        expect do
          described_class.new(tool_calls: "invalid")
        end.to raise_error(ArgumentError, "tool_calls must be an array")
      end

      it "raises an error for malformed tool_calls" do
        invalid_tool_calls = [{ id: "call_123" }] # missing type and function

        expect do
          described_class.new(tool_calls: invalid_tool_calls)
        end.to raise_error(ArgumentError, "Invalid tool_call format")
      end
    end

    describe "#to_h" do
      it "returns hash with content only" do
        message = described_class.new(content: "Hello!")

        expect(message.to_h).to eq({
                                     role: "assistant",
                                     content: "Hello!"
                                   })
      end

      it "returns hash with tool_calls only" do
        tool_calls = [
          {
            id: "call_123",
            type: "function",
            function: { name: "get_weather", arguments: '{"location": "Paris"}' }
          }
        ]

        message = described_class.new(tool_calls: tool_calls)

        expect(message.to_h).to eq({
                                     role: "assistant",
                                     tool_calls: tool_calls
                                   })
      end

      it "returns hash with both content and tool_calls" do
        tool_calls = [
          {
            id: "call_123",
            type: "function",
            function: { name: "get_weather", arguments: '{"location": "Paris"}' }
          }
        ]

        message = described_class.new(
          content: "I'll check the weather.",
          tool_calls: tool_calls
        )

        expect(message.to_h).to eq({
                                     role: "assistant",
                                     content: "I'll check the weather.",
                                     tool_calls: tool_calls
                                   })
      end
    end
  end

  describe MistralAI::Messages::ToolMessage do
    describe "#initialize" do
      it "creates a tool message" do
        message = described_class.new(
          content: "Weather in Paris: 22°C, sunny",
          tool_call_id: "call_123"
        )

        expect(message.role).to eq("tool")
        expect(message.content).to eq("Weather in Paris: 22°C, sunny")
        expect(message.tool_call_id).to eq("call_123")
      end

      it "raises an error for nil content" do
        expect do
          described_class.new(content: nil, tool_call_id: "call_123")
        end.to raise_error(ArgumentError, "Content cannot be nil or empty")
      end

      it "raises an error for nil tool_call_id" do
        expect do
          described_class.new(content: "Result", tool_call_id: nil)
        end.to raise_error(ArgumentError, "tool_call_id cannot be nil or empty")
      end
    end

    describe "#to_h" do
      it "returns a hash representation" do
        message = described_class.new(
          content: "Weather result",
          tool_call_id: "call_123"
        )

        expect(message.to_h).to eq({
                                     role: "tool",
                                     content: "Weather result",
                                     tool_call_id: "call_123"
                                   })
      end
    end
  end

  describe MistralAI::Messages::MessageBuilder do
    describe ".build" do
      it "builds a user message from hash" do
        hash = { role: "user", content: "Hello" }
        message = described_class.build(hash)

        expect(message).to be_a(MistralAI::Messages::UserMessage)
        expect(message.content).to eq("Hello")
      end

      it "builds a system message from hash" do
        hash = { role: "system", content: "You are helpful" }
        message = described_class.build(hash)

        expect(message).to be_a(MistralAI::Messages::SystemMessage)
        expect(message.content).to eq("You are helpful")
      end

      it "builds an assistant message from hash" do
        hash = { role: "assistant", content: "Hi there!" }
        message = described_class.build(hash)

        expect(message).to be_a(MistralAI::Messages::AssistantMessage)
        expect(message.content).to eq("Hi there!")
      end

      it "builds a tool message from hash" do
        hash = { role: "tool", content: "Result", tool_call_id: "call_123" }
        message = described_class.build(hash)

        expect(message).to be_a(MistralAI::Messages::ToolMessage)
        expect(message.content).to eq("Result")
        expect(message.tool_call_id).to eq("call_123")
      end

      it "handles string keys in hash" do
        hash = { "role" => "user", "content" => "Hello" }
        message = described_class.build(hash)

        expect(message).to be_a(MistralAI::Messages::UserMessage)
        expect(message.content).to eq("Hello")
      end

      it "returns message objects unchanged" do
        original_message = MistralAI::Messages::UserMessage.new(content: "Test")
        result = described_class.build(original_message)

        expect(result).to be(original_message)
      end

      it "raises an error for unknown role" do
        hash = { role: "unknown", content: "Test" }

        expect do
          described_class.build(hash)
        end.to raise_error(ArgumentError, "Unknown message role: unknown")
      end

      it "raises an error for invalid format" do
        expect do
          described_class.build("invalid")
        end.to raise_error(ArgumentError, "Invalid message format: String")
      end
    end

    describe ".build_messages" do
      it "builds an array of messages" do
        messages = [
          { role: "system", content: "You are helpful" },
          { role: "user", content: "Hello" },
          { role: "assistant", content: "Hi there!" }
        ]

        result = described_class.build_messages(messages)

        expect(result.length).to eq(3)
        expect(result[0]).to be_a(MistralAI::Messages::SystemMessage)
        expect(result[1]).to be_a(MistralAI::Messages::UserMessage)
        expect(result[2]).to be_a(MistralAI::Messages::AssistantMessage)
      end

      it "handles single message input" do
        message = { role: "user", content: "Hello" }
        result = described_class.build_messages(message)

        expect(result.length).to eq(1)
        expect(result[0]).to be_a(MistralAI::Messages::UserMessage)
      end

      it "handles empty input" do
        result = described_class.build_messages([])
        expect(result).to be_empty
      end
    end
  end
end
