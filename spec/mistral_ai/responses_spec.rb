# frozen_string_literal: true

RSpec.describe MistralAI::Responses do
  describe MistralAI::Responses::Usage do
    describe "#initialize" do
      it "initializes with symbol keys" do
        data = {
          prompt_tokens: 10,
          completion_tokens: 20,
          total_tokens: 30
        }
        
        usage = described_class.new(data)
        
        expect(usage.prompt_tokens).to eq(10)
        expect(usage.completion_tokens).to eq(20)
        expect(usage.total_tokens).to eq(30)
      end

      it "initializes with string keys" do
        data = {
          "prompt_tokens" => 15,
          "completion_tokens" => 25,
          "total_tokens" => 40
        }
        
        usage = described_class.new(data)
        
        expect(usage.prompt_tokens).to eq(15)
        expect(usage.completion_tokens).to eq(25)
        expect(usage.total_tokens).to eq(40)
      end
    end

    describe "#to_h" do
      it "returns a hash representation" do
        data = {
          prompt_tokens: 10,
          completion_tokens: 20,
          total_tokens: 30
        }
        
        usage = described_class.new(data)
        
        expect(usage.to_h).to eq({
          prompt_tokens: 10,
          completion_tokens: 20,
          total_tokens: 30
        })
      end
    end
  end

  describe MistralAI::Responses::Message do
    describe "#initialize" do
      it "initializes a simple message" do
        data = {
          "role" => "assistant",
          "content" => "Hello! How can I help you?"
        }
        
        message = described_class.new(data)
        
        expect(message.role).to eq("assistant")
        expect(message.content).to eq("Hello! How can I help you?")
        expect(message.tool_calls).to be_nil
      end

      it "initializes a message with tool calls" do
        data = {
          "role" => "assistant",
          "content" => nil,
          "tool_calls" => [
            {
              "id" => "call_123",
              "type" => "function",
              "function" => {
                "name" => "get_weather",
                "arguments" => '{"location": "Paris"}'
              }
            }
          ]
        }
        
        message = described_class.new(data)
        
        expect(message.role).to eq("assistant")
        expect(message.content).to be_nil
        expect(message.tool_calls).to eq([
          {
            id: "call_123",
            type: "function",
            function: {
              name: "get_weather",
              arguments: '{"location": "Paris"}'
            }
          }
        ])
      end

      it "handles empty tool_calls" do
        data = {
          "role" => "assistant",
          "content" => "Hello",
          "tool_calls" => []
        }
        
        message = described_class.new(data)
        
        expect(message.role).to eq("assistant")
        expect(message.content).to eq("Hello")
        expect(message.tool_calls).to be_nil
      end
    end

    describe "#to_h" do
      it "returns hash with content only" do
        data = { "role" => "assistant", "content" => "Hello" }
        message = described_class.new(data)
        
        expect(message.to_h).to eq({
          role: "assistant",
          content: "Hello"
        })
      end

      it "returns hash with tool_calls" do
        data = {
          "role" => "assistant",
          "tool_calls" => [
            {
              "id" => "call_123",
              "type" => "function",
              "function" => { "name" => "get_weather" }
            }
          ]
        }
        
        message = described_class.new(data)
        
        expect(message.to_h).to eq({
          role: "assistant",
          tool_calls: [
            {
              id: "call_123",
              type: "function",
              function: { name: "get_weather" }
            }
          ]
        })
      end
    end
  end

  describe MistralAI::Responses::Delta do
    describe "#initialize" do
      it "initializes with content" do
        data = { "content" => "Hello" }
        delta = described_class.new(data)
        
        expect(delta.content).to eq("Hello")
        expect(delta.role).to be_nil
        expect(delta.tool_calls).to be_nil
      end

      it "initializes with role" do
        data = { "role" => "assistant" }
        delta = described_class.new(data)
        
        expect(delta.role).to eq("assistant")
        expect(delta.content).to be_nil
      end

      it "initializes with tool_calls" do
        data = {
          "tool_calls" => [
            {
              "id" => "call_123",
              "function" => { "name" => "get_weather" }
            }
          ]
        }
        
        delta = described_class.new(data)
        
        expect(delta.tool_calls).to eq([
          {
            id: "call_123",
            function: { name: "get_weather" }
          }
        ])
      end
    end

    describe "#to_h" do
      it "returns hash with only non-nil values" do
        data = { "content" => "Hello" }
        delta = described_class.new(data)
        
        expect(delta.to_h).to eq({ content: "Hello" })
      end

      it "returns empty hash when all values are nil" do
        data = {}
        delta = described_class.new(data)
        
        expect(delta.to_h).to eq({})
      end
    end
  end

  describe MistralAI::Responses::Choice do
    describe "#initialize" do
      it "initializes a choice" do
        data = {
          "index" => 0,
          "message" => {
            "role" => "assistant",
            "content" => "Hello!"
          },
          "finish_reason" => "stop"
        }
        
        choice = described_class.new(data)
        
        expect(choice.index).to eq(0)
        expect(choice.message).to be_a(MistralAI::Responses::Message)
        expect(choice.message.content).to eq("Hello!")
        expect(choice.finish_reason).to eq("stop")
      end

      it "handles nil message" do
        data = {
          "index" => 0,
          "finish_reason" => "stop"
        }
        
        choice = described_class.new(data)
        
        expect(choice.index).to eq(0)
        expect(choice.message).to be_nil
        expect(choice.finish_reason).to eq("stop")
      end
    end

    describe "#to_h" do
      it "returns a hash representation" do
        data = {
          "index" => 0,
          "message" => { "role" => "assistant", "content" => "Hello!" },
          "finish_reason" => "stop"
        }
        
        choice = described_class.new(data)
        
        expect(choice.to_h).to eq({
          index: 0,
          message: { role: "assistant", content: "Hello!" },
          finish_reason: "stop"
        })
      end
    end
  end

  describe MistralAI::Responses::StreamChoice do
    describe "#initialize" do
      it "initializes a stream choice" do
        data = {
          "index" => 0,
          "delta" => { "content" => "Hello" },
          "finish_reason" => nil
        }
        
        choice = described_class.new(data)
        
        expect(choice.index).to eq(0)
        expect(choice.delta).to be_a(MistralAI::Responses::Delta)
        expect(choice.delta.content).to eq("Hello")
        expect(choice.finish_reason).to be_nil
      end
    end

    describe "#to_h" do
      it "returns a hash representation" do
        data = {
          "index" => 0,
          "delta" => { "content" => "Hello" },
          "finish_reason" => "stop"
        }
        
        choice = described_class.new(data)
        
        expect(choice.to_h).to eq({
          index: 0,
          delta: { content: "Hello" },
          finish_reason: "stop"
        })
      end
    end
  end

  describe MistralAI::Responses::ChatResponse do
    let(:sample_response_data) do
      {
        "id" => "chatcmpl-123",
        "object" => "chat.completion",
        "created" => 1677652288,
        "model" => "mistral-small-latest",
        "choices" => [
          {
            "index" => 0,
            "message" => {
              "role" => "assistant",
              "content" => "Hello! How can I help you today?"
            },
            "finish_reason" => "stop"
          }
        ],
        "usage" => {
          "prompt_tokens" => 10,
          "completion_tokens" => 20,
          "total_tokens" => 30
        }
      }
    end

    describe "#initialize" do
      it "initializes a complete chat response" do
        response = described_class.new(sample_response_data)
        
        expect(response.id).to eq("chatcmpl-123")
        expect(response.object).to eq("chat.completion")
        expect(response.created).to eq(1677652288)
        expect(response.model).to eq("mistral-small-latest")
        expect(response.choices.length).to eq(1)
        expect(response.choices.first).to be_a(MistralAI::Responses::Choice)
        expect(response.usage).to be_a(MistralAI::Responses::Usage)
      end

      it "handles missing usage" do
        data = sample_response_data.dup
        data.delete("usage")
        
        response = described_class.new(data)
        
        expect(response.usage).to be_nil
      end

      it "handles symbol keys" do
        data = {
          id: "chatcmpl-123",
          object: "chat.completion",
          created: 1677652288,
          model: "mistral-small-latest",
          choices: [],
          usage: { prompt_tokens: 10 }
        }
        
        response = described_class.new(data)
        
        expect(response.id).to eq("chatcmpl-123")
        expect(response.model).to eq("mistral-small-latest")
      end
    end

    describe "convenience methods" do
      let(:response) { described_class.new(sample_response_data) }

      describe "#content" do
        it "returns the first choice message content" do
          expect(response.content).to eq("Hello! How can I help you today?")
        end

        it "returns nil when no choices" do
          data = sample_response_data.dup
          data["choices"] = []
          response = described_class.new(data)
          
          expect(response.content).to be_nil
        end
      end

      describe "#message" do
        it "returns the first choice message" do
          message = response.message
          
          expect(message).to be_a(MistralAI::Responses::Message)
          expect(message.content).to eq("Hello! How can I help you today?")
        end
      end

      describe "#finish_reason" do
        it "returns the first choice finish reason" do
          expect(response.finish_reason).to eq("stop")
        end
      end
    end

    describe "#to_h" do
      it "returns a complete hash representation" do
        response = described_class.new(sample_response_data)
        hash = response.to_h
        
        expect(hash[:id]).to eq("chatcmpl-123")
        expect(hash[:object]).to eq("chat.completion")
        expect(hash[:created]).to eq(1677652288)
        expect(hash[:model]).to eq("mistral-small-latest")
        expect(hash[:choices]).to be_a(Array)
        expect(hash[:usage]).to be_a(Hash)
      end
    end
  end

  describe MistralAI::Responses::ChatStreamResponse do
    let(:sample_stream_data) do
      {
        "id" => "chatcmpl-123",
        "object" => "chat.completion.chunk",
        "created" => 1677652288,
        "model" => "mistral-small-latest",
        "choices" => [
          {
            "index" => 0,
            "delta" => { "content" => "Hello" },
            "finish_reason" => nil
          }
        ]
      }
    end

    describe "#initialize" do
      it "initializes a stream response" do
        response = described_class.new(sample_stream_data)
        
        expect(response.id).to eq("chatcmpl-123")
        expect(response.object).to eq("chat.completion.chunk")
        expect(response.created).to eq(1677652288)
        expect(response.model).to eq("mistral-small-latest")
        expect(response.choices.length).to eq(1)
        expect(response.choices.first).to be_a(MistralAI::Responses::StreamChoice)
      end
    end

    describe "convenience methods" do
      let(:response) { described_class.new(sample_stream_data) }

      describe "#content" do
        it "returns the first choice delta content" do
          expect(response.content).to eq("Hello")
        end
      end

      describe "#delta" do
        it "returns the first choice delta" do
          delta = response.delta
          
          expect(delta).to be_a(MistralAI::Responses::Delta)
          expect(delta.content).to eq("Hello")
        end
      end

      describe "#finish_reason" do
        it "returns the first choice finish reason" do
          expect(response.finish_reason).to be_nil
        end
      end
    end

    describe "#to_h" do
      it "returns a hash representation" do
        response = described_class.new(sample_stream_data)
        hash = response.to_h
        
        expect(hash[:id]).to eq("chatcmpl-123")
        expect(hash[:object]).to eq("chat.completion.chunk")
        expect(hash[:choices]).to be_a(Array)
      end
    end
  end
end 