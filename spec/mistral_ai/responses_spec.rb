# frozen_string_literal: true

require "spec_helper"

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
    let(:basic_response_data) do
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
          "prompt_tokens" => 9,
          "completion_tokens" => 12,
          "total_tokens" => 21
        }
      }
    end

    let(:tool_response_data) do
      {
        "id" => "chatcmpl-456",
        "object" => "chat.completion",
        "created" => 1677652288,
        "model" => "mistral-small-latest",
        "choices" => [
          {
            "index" => 0,
            "message" => {
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
            },
            "finish_reason" => "tool_calls"
          }
        ],
        "usage" => {
          "prompt_tokens" => 15,
          "completion_tokens" => 5,
          "total_tokens" => 20
        }
      }
    end

    let(:json_response_data) do
      {
        "id" => "chatcmpl-789",
        "object" => "chat.completion",
        "created" => 1677652288,
        "model" => "mistral-small-latest",
        "choices" => [
          {
            "index" => 0,
            "message" => {
              "role" => "assistant",
              "content" => '{"name": "John Doe", "age": 30, "active": true}'
            },
            "finish_reason" => "stop"
          }
        ],
        "usage" => {
          "prompt_tokens" => 20,
          "completion_tokens" => 15,
          "total_tokens" => 35
        }
      }
    end

    describe "basic functionality" do
      let(:response) { described_class.new(basic_response_data) }

      it "initializes with response data" do
        expect(response.id).to eq("chatcmpl-123")
        expect(response.object).to eq("chat.completion")
        expect(response.model).to eq("mistral-small-latest")
        expect(response.content).to eq("Hello! How can I help you today?")
        expect(response.finish_reason).to eq("stop")
      end

      it "provides usage information" do
        expect(response.usage).to be_a(MistralAI::Responses::Usage)
        expect(response.usage.total_tokens).to eq(21)
        expect(response.usage.prompt_tokens).to eq(9)
        expect(response.usage.completion_tokens).to eq(12)
      end

      it "converts to hash" do
        hash = response.to_h
        expect(hash[:id]).to eq("chatcmpl-123")
        expect(hash[:choices]).to be_an(Array)
        expect(hash[:usage]).to be_a(Hash)
        expect(hash[:choices].first[:message][:content]).to eq("Hello! How can I help you today?")
      end
    end

    # Phase 4: Tool calling support tests
    describe "tool calling functionality" do
      let(:response) { described_class.new(tool_response_data) }

      describe "#has_tool_calls?" do
        it "returns true when tool calls are present" do
          expect(response.has_tool_calls?).to be true
        end

        it "returns false when no tool calls" do
          basic_response = described_class.new(basic_response_data)
          expect(basic_response.has_tool_calls?).to be false
        end
      end

      describe "#tool_calls" do
        it "returns tool calls array" do
          tool_calls = response.tool_calls
          expect(tool_calls).to be_an(Array)
          expect(tool_calls.length).to eq(1)
          
          tool_call = tool_calls.first
          expect(tool_call[:id]).to eq("call_123")
          expect(tool_call[:type]).to eq("function")
          expect(tool_call[:function][:name]).to eq("get_weather")
        end

        it "returns empty array when no tool calls" do
          basic_response = described_class.new(basic_response_data)
          expect(basic_response.tool_calls).to eq([])
        end
      end

      describe "#extract_tool_calls" do
        it "extracts tool calls as ToolCall objects" do
          # Skip if Tools module not loaded
          skip "Tools module not available" unless defined?(MistralAI::Tools::ToolUtils)
          
          tool_calls = response.extract_tool_calls
          expect(tool_calls).to be_an(Array)
          expect(tool_calls.length).to eq(1)
          
          tool_call = tool_calls.first
          expect(tool_call).to be_a(MistralAI::Tools::ToolCall)
          expect(tool_call.id).to eq("call_123")
          expect(tool_call.function_name).to eq("get_weather")
          expect(tool_call.parsed_arguments).to eq({"location" => "Paris"})
        end

        it "returns empty array when no tool calls" do
          basic_response = described_class.new(basic_response_data)
          expect(basic_response.extract_tool_calls).to eq([])
        end

        it "returns empty array when Tools module not loaded" do
          # Temporarily hide the Tools module
          tools_module = MistralAI.send(:remove_const, :Tools) if defined?(MistralAI::Tools)
          
          begin
            expect(response.extract_tool_calls).to eq([])
          ensure
            MistralAI.const_set(:Tools, tools_module) if tools_module
          end
        end
      end
    end

    # Phase 4: Structured outputs support tests
    describe "structured outputs functionality" do
      let(:response) { described_class.new(json_response_data) }

      describe "#structured_content" do
        it "parses JSON content as structured object" do
          # Skip if StructuredOutputs module not loaded
          skip "StructuredOutputs module not available" unless defined?(MistralAI::StructuredOutputs::ObjectMapper)
          
          structured = response.structured_content
          expect(structured).to be_a(MistralAI::StructuredOutputs::StructuredObject)
          expect(structured.name).to eq("John Doe")
          expect(structured.age).to eq(30)
          expect(structured.active).to be true
        end

        it "parses with schema class" do
          # Skip if StructuredOutputs module not loaded
          skip "StructuredOutputs module not available" unless defined?(MistralAI::StructuredOutputs::BaseSchema)
          
          schema_class = Class.new(MistralAI::StructuredOutputs::BaseSchema) do
            string_property :name, required: true
            integer_property :age, required: true
            boolean_property :active
          end

          structured = response.structured_content(schema_class)
          expect(structured).to be_a(schema_class)
          expect(structured.name).to eq("John Doe")
          expect(structured.age).to eq(30)
          expect(structured.active).to be true
        end

        it "falls back to JSON.parse when StructuredOutputs not available" do
          # Temporarily hide the StructuredOutputs module
          structured_module = MistralAI.send(:remove_const, :StructuredOutputs) if defined?(MistralAI::StructuredOutputs)
          
          begin
            structured = response.structured_content
            expect(structured).to be_a(Hash)
            expect(structured["name"]).to eq("John Doe")
            expect(structured["age"]).to eq(30)
          ensure
            MistralAI.const_set(:StructuredOutputs, structured_module) if structured_module
          end
        end

        it "returns content as-is for invalid JSON" do
          invalid_json_data = basic_response_data.dup
          invalid_json_data["choices"][0]["message"]["content"] = "Not valid JSON"
          invalid_response = described_class.new(invalid_json_data)
          
          result = invalid_response.structured_content
          expect(result).to eq("Not valid JSON")
        end

        it "returns nil when no content" do
          tool_response = described_class.new(tool_response_data)
          expect(tool_response.structured_content).to be_nil
        end
      end

      describe "#validate_schema" do
        let(:schema) do
          {
            type: "object",
            properties: {
              name: { type: "string" },
              age: { type: "integer" },
              active: { type: "boolean" }
            },
            required: ["name", "age"]
          }
        end

        it "validates response against schema" do
          # Skip if StructuredOutputs module not loaded
          skip "StructuredOutputs module not available" unless defined?(MistralAI::StructuredOutputs::Utils)
          
          expect(response.validate_schema(schema)).to be true
        end

        it "returns false for invalid schema" do
          # Skip if StructuredOutputs module not loaded
          skip "StructuredOutputs module not available" unless defined?(MistralAI::StructuredOutputs::Utils)
          
          invalid_schema = {
            type: "object",
            properties: {
              email: { type: "string" }
            },
            required: ["email"]
          }
          
          expect(response.validate_schema(invalid_schema)).to be false
        end

        it "returns false when StructuredOutputs not available" do
          # Temporarily hide the StructuredOutputs module
          structured_module = MistralAI.send(:remove_const, :StructuredOutputs) if defined?(MistralAI::StructuredOutputs)
          
          begin
            expect(response.validate_schema(schema)).to be false
          ensure
            MistralAI.const_set(:StructuredOutputs, structured_module) if structured_module
          end
        end

        it "returns false when no content" do
          tool_response = described_class.new(tool_response_data)
          expect(tool_response.validate_schema(schema)).to be false
        end
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