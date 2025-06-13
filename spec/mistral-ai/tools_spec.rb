# frozen_string_literal: true

require "spec_helper"

RSpec.describe MistralAI::Tools do
  describe MistralAI::Tools::FunctionTool do
    describe "#initialize" do
      it "creates a function tool with name and description" do
        tool = described_class.new(
          name: "test_function",
          description: "A test function"
        )

        expect(tool.type).to eq("function")
        expect(tool.name).to eq("test_function")
        expect(tool.description).to eq("A test function")
      end

      it "creates a function tool with parameters" do
        parameters = {
          type: "object",
          properties: {
            query: { type: "string", description: "Search query" }
          },
          required: ["query"]
        }

        tool = described_class.new(
          name: "search",
          description: "Search function",
          parameters: parameters
        )

        expect(tool.parameters).to eq(parameters)
      end

      it "validates function name format" do
        expect {
          described_class.new(name: "invalid-name!", description: "Test")
        }.to raise_error(ArgumentError, /Function name must be a valid identifier/)
      end

      it "validates function name is not empty" do
        expect {
          described_class.new(name: "", description: "Test")
        }.to raise_error(ArgumentError, /Function name cannot be nil or empty/)
      end
    end

    describe "#to_h" do
      it "returns correct hash representation" do
        tool = described_class.new(
          name: "test_function",
          description: "A test function",
          parameters: {
            type: "object",
            properties: { query: { type: "string" } }
          }
        )

        hash = tool.to_h
        expect(hash[:type]).to eq("function")
        expect(hash[:function][:name]).to eq("test_function")
        expect(hash[:function][:description]).to eq("A test function")
        expect(hash[:function][:parameters]).to include(:type, :properties)
      end
    end
  end

  describe MistralAI::Tools::ToolChoice do
    describe ".auto" do
      it "creates auto tool choice" do
        choice = described_class.auto
        expect(choice.auto?).to be true
        expect(choice.to_h).to eq("auto")
      end
    end

    describe ".none" do
      it "creates none tool choice" do
        choice = described_class.none
        expect(choice.none?).to be true
        expect(choice.to_h).to eq("none")
      end
    end

    describe ".function" do
      it "creates function-specific tool choice" do
        choice = described_class.function("my_function")
        expect(choice.function?).to be true
        expect(choice.to_h).to eq({
          type: "function",
          function: { name: "my_function" }
        })
      end

      it "validates function name is provided" do
        expect {
          described_class.function("")
        }.to raise_error(ArgumentError, /Function name required/)
      end
    end

    describe "#initialize" do
      it "validates choice type" do
        expect {
          described_class.new("invalid")
        }.to raise_error(ArgumentError, /Invalid tool choice type/)
      end
    end
  end

  describe MistralAI::Tools::ToolBuilder do
    describe ".function" do
      it "builds a simple function tool" do
        tool = described_class.function("test") do
          description "Test function"
        end

        expect(tool).to be_a(MistralAI::Tools::FunctionTool)
        expect(tool.name).to eq("test")
        expect(tool.description).to eq("Test function")
      end

      it "builds a function with parameters" do
        tool = described_class.function("search") do
          description "Search function"
          string_parameter "query", description: "Search query", required: true
          integer_parameter "limit", description: "Result limit", minimum: 1, maximum: 100
          boolean_parameter "exact_match", description: "Exact match only"
        end

        params = tool.parameters
        expect(params[:type]).to eq("object")
        expect(params[:properties]["query"][:type]).to eq("string")
        expect(params[:properties]["limit"][:type]).to eq("integer")
        expect(params[:properties]["limit"][:minimum]).to eq(1)
        expect(params[:properties]["limit"][:maximum]).to eq(100)
        expect(params[:properties]["exact_match"][:type]).to eq("boolean")
        expect(params[:required]).to include("query")
      end

      it "builds with enum parameters" do
        tool = described_class.function("format") do
          string_parameter "output_format", enum: ["json", "xml", "csv"], required: true
        end

        expect(tool.parameters[:properties]["output_format"][:enum]).to eq(["json", "xml", "csv"])
      end

      it "builds with array parameters" do
        tool = described_class.function("process") do
          array_parameter "items", items: { type: "string" }, required: true
        end

        expect(tool.parameters[:properties]["items"][:type]).to eq("array")
        expect(tool.parameters[:properties]["items"][:items]).to eq({ type: "string" })
      end
    end
  end

  describe MistralAI::Tools::ToolCall do
    describe "#initialize" do
      it "creates a tool call with required fields" do
        tool_call = described_class.new(
          id: "call_123",
          type: "function",
          function: { name: "test_function", arguments: '{"query": "test"}' }
        )

        expect(tool_call.id).to eq("call_123")
        expect(tool_call.type).to eq("function")
        expect(tool_call.function_name).to eq("test_function")
        expect(tool_call.function_arguments).to eq('{"query": "test"}')
      end

      it "validates required fields" do
        expect {
          described_class.new(id: "", type: "function", function: {})
        }.to raise_error(ArgumentError, /Tool call ID cannot be nil or empty/)

        expect {
          described_class.new(id: "call_123", type: "", function: {})
        }.to raise_error(ArgumentError, /Tool call type cannot be nil or empty/)

        expect {
          described_class.new(id: "call_123", type: "function", function: nil)
        }.to raise_error(ArgumentError, /Tool call function cannot be nil/)
      end
    end

    describe "#parsed_arguments" do
      it "parses JSON string arguments" do
        tool_call = described_class.new(
          id: "call_123",
          type: "function",
          function: { name: "test", arguments: '{"query": "test", "limit": 10}' }
        )

        parsed = tool_call.parsed_arguments
        expect(parsed["query"]).to eq("test")
        expect(parsed["limit"]).to eq(10)
      end

      it "returns hash arguments as-is" do
        args = { "query" => "test", "limit" => 10 }
        tool_call = described_class.new(
          id: "call_123",
          type: "function",
          function: { name: "test", arguments: args }
        )

        expect(tool_call.parsed_arguments).to eq(args)
      end

      it "returns empty hash for invalid JSON" do
        tool_call = described_class.new(
          id: "call_123",
          type: "function",
          function: { name: "test", arguments: "invalid json" }
        )

        expect(tool_call.parsed_arguments).to eq({})
      end
    end
  end

  describe MistralAI::Tools::ToolUtils do
    describe ".validate_tools" do
      it "validates array of tool hashes" do
        tools = [
          {
            type: "function",
            function: { name: "test1" }
          },
          {
            type: "function", 
            function: { name: "test2" }
          }
        ]

        expect { described_class.validate_tools(tools) }.not_to raise_error
      end

      it "validates array of tool objects" do
        tools = [
          MistralAI::Tools::FunctionTool.new(name: "test1"),
          MistralAI::Tools::FunctionTool.new(name: "test2")
        ]

        expect { described_class.validate_tools(tools) }.not_to raise_error
      end

      it "raises error for non-array" do
        expect {
          described_class.validate_tools("not an array")
        }.to raise_error(ArgumentError, /Tools must be an array/)
      end

      it "raises error for invalid tool format" do
        tools = [{ type: "function" }]  # Missing function

        expect {
          described_class.validate_tools(tools)
        }.to raise_error(ArgumentError, /must have 'type' and 'function'/)
      end

      it "raises error for invalid tool type" do
        tools = ["invalid tool"]

        expect {
          described_class.validate_tools(tools)
        }.to raise_error(ArgumentError, /Invalid tool type/)
      end
    end

    describe ".create_tool_message" do
      it "creates a tool message" do
        message = described_class.create_tool_message(
          tool_call_id: "call_123",
          content: "Tool result"
        )

        expect(message).to be_a(MistralAI::Messages::ToolMessage)
        expect(message.tool_call_id).to eq("call_123")
        expect(message.content).to eq("Tool result")
        expect(message.role).to eq("tool")
      end
    end

    describe ".extract_tool_calls" do
      let(:response_data) do
        {
          "id" => "chatcmpl-123",
          "object" => "chat.completion",
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
          ]
        }
      end

      it "extracts tool calls from response" do
        response = MistralAI::Responses::ChatResponse.new(response_data)
        tool_calls = described_class.extract_tool_calls(response)

        expect(tool_calls.length).to eq(1)
        expect(tool_calls.first).to be_a(MistralAI::Tools::ToolCall)
        expect(tool_calls.first.id).to eq("call_123")
        expect(tool_calls.first.function_name).to eq("get_weather")
      end

      it "returns empty array for response without tool calls" do
        response_data["choices"][0]["message"]["tool_calls"] = nil
        response = MistralAI::Responses::ChatResponse.new(response_data)
        tool_calls = described_class.extract_tool_calls(response)

        expect(tool_calls).to be_empty
      end
    end
  end
end 