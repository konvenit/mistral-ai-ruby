# frozen_string_literal: true

require "spec_helper"

RSpec.describe MistralAI::Resources::Chat do
  let(:configuration) { MistralAI::Configuration.new }
  let(:http_client) { instance_double(MistralAI::HTTPClient) }
  let(:client) { instance_double(MistralAI::Client, http_client: http_client) }
  let(:chat_resource) { described_class.new(client) }

  describe "#complete" do
    let(:response_data) do
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

    before do
      allow(http_client).to receive(:post).and_return(response_data)
    end

    it "completes chat with basic parameters" do
      response = chat_resource.complete(
        model: "mistral-small-latest",
        messages: [{ role: "user", content: "Hello" }]
      )

      expect(response).to be_a(MistralAI::Responses::ChatResponse)
      expect(response.content).to eq("Hello! How can I help you today?")
      expect(response.model).to eq("mistral-small-latest")
    end

    # Phase 4: Tool calling integration tests
    describe "with tools" do
      let(:weather_tool) do
        {
          type: "function",
          function: {
            name: "get_weather",
            description: "Get weather information",
            parameters: {
              type: "object",
              properties: {
                location: { type: "string", description: "City name" }
              },
              required: ["location"]
            }
          }
        }
      end

      it "accepts tool objects" do
        tool_obj = MistralAI::Tools::FunctionTool.new(
          name: "test_function",
          description: "Test function"
        )

        expect {
          chat_resource.complete(
            model: "mistral-small-latest",
            messages: [{ role: "user", content: "Test" }],
            tools: [tool_obj]
          )
        }.not_to raise_error
      end

      it "accepts tool choice objects" do
        tool_choice = MistralAI::Tools::ToolChoice.auto

        expect {
          chat_resource.complete(
            model: "mistral-small-latest",
            messages: [{ role: "user", content: "Test" }],
            tools: [weather_tool],
            tool_choice: tool_choice
          )
        }.not_to raise_error
      end

      it "validates tool format" do
        invalid_tools = [{ type: "function" }]  # Missing function

        expect {
          chat_resource.complete(
            model: "mistral-small-latest",
            messages: [{ role: "user", content: "Test" }],
            tools: invalid_tools
          )
        }.to raise_error(ArgumentError, /Tool at index 0 must have 'type' and 'function' keys/)
      end

      it "validates tool choice format" do
        expect {
          chat_resource.complete(
            model: "mistral-small-latest",
            messages: [{ role: "user", content: "Test" }],
            tools: [weather_tool],
            tool_choice: "invalid_choice"
          )
        }.to raise_error(ArgumentError, /tool_choice must be/)
      end
    end

    # Phase 4: Structured outputs integration tests
    describe "with structured response format" do
      let(:json_schema) do
        {
          type: "object",
          properties: {
            name: { type: "string" },
            age: { type: "integer" }
          },
          required: ["name"]
        }
      end

      it "accepts response format with schema" do
        expect {
          chat_resource.complete(
            model: "mistral-small-latest",
            messages: [{ role: "user", content: "Generate user data" }],
            response_format: {
              type: "json_object",
              schema: json_schema
            }
          )
        }.not_to raise_error
      end

      it "validates response format structure" do
        expect {
          chat_resource.complete(
            model: "mistral-small-latest",
            messages: [{ role: "user", content: "Test" }],
            response_format: { type: "invalid_type" }
          )
        }.to raise_error(ArgumentError, /response_format type must be one of/)
      end

      it "accepts schema class response format" do
        schema_class = Class.new(MistralAI::StructuredOutputs::BaseSchema) do
          string_property :name, required: true
        end

        expect {
          chat_resource.complete(
            model: "mistral-small-latest",
            messages: [{ role: "user", content: "Test" }],
            response_format: schema_class.response_format
          )
        }.not_to raise_error
      end
    end

    describe "parameter validation" do
      it "validates required parameters" do
        expect {
          chat_resource.complete(messages: [{ role: "user", content: "Hello" }])
        }.to raise_error(ArgumentError)
      end

      it "transforms stop parameter to array" do
        expect(http_client).to receive(:post) do |_path, options|
          expect(options[:body][:stop]).to eq(["stop"])
          response_data
        end

        chat_resource.complete(
          model: "mistral-small-latest",
          messages: [{ role: "user", content: "Hello" }],
          stop: "stop"
        )
      end

      it "passes through valid parameters" do
        expect(http_client).to receive(:post) do |_path, options|
          body = options[:body]
          expect(body[:temperature]).to eq(0.7)
          expect(body[:max_tokens]).to eq(100)
          expect(body[:top_p]).to eq(0.9)
          response_data
        end

        chat_resource.complete(
          model: "mistral-small-latest",
          messages: [{ role: "user", content: "Hello" }],
          temperature: 0.7,
          max_tokens: 100,
          top_p: 0.9
        )
      end
    end
  end

  describe "#stream" do
    let(:streaming_handler) { instance_double(MistralAI::Streaming::StreamHandler) }
    let(:stream_enumerator) { instance_double(MistralAI::Streaming::StreamEnumerator) }

    before do
      allow(MistralAI::Streaming::StreamHandler).to receive(:new).and_return(streaming_handler)
      allow(MistralAI::Streaming::StreamEnumerator).to receive(:new).and_return(stream_enumerator)
    end

    it "streams with block" do
      expect(streaming_handler).to receive(:stream)

      chat_resource.stream(
        model: "mistral-small-latest",
        messages: [{ role: "user", content: "Hello" }]
      ) { |chunk| puts chunk }
    end

    it "returns enumerator without block" do
      result = chat_resource.stream(
        model: "mistral-small-latest",
        messages: [{ role: "user", content: "Hello" }]
      )

      expect(result).to eq(stream_enumerator)
    end

    it "streams with tools" do
      tool = MistralAI::Tools::FunctionTool.new(name: "test_function")

      expect(streaming_handler).to receive(:stream) do |**options|
        expect(options[:body][:tools]).to be_an(Array)
        expect(options[:body][:tools].length).to eq(1)
      end

      chat_resource.stream(
        model: "mistral-small-latest",
        messages: [{ role: "user", content: "Hello" }],
        tools: [tool]
      ) { |chunk| puts chunk }
    end
  end

  describe "error handling" do
    it "handles API errors" do
      allow(http_client).to receive(:post).and_raise(MistralAI::APIError.new("API Error"))

      expect {
        chat_resource.complete(
          model: "mistral-small-latest",
          messages: [{ role: "user", content: "Hello" }]
        )
      }.to raise_error(MistralAI::APIError)
    end

    it "wraps unexpected errors" do
      allow(http_client).to receive(:post).and_raise(StandardError.new("Unexpected error"))

      expect {
        chat_resource.complete(
          model: "mistral-small-latest",
          messages: [{ role: "user", content: "Hello" }]
        )
      }.to raise_error(MistralAI::APIError, /Chat completion failed/)
    end

    it "preserves argument errors" do
      expect {
        chat_resource.complete(
          model: "mistral-small-latest",
          messages: [{ role: "user", content: "Hello" }],
          tools: "invalid"
        )
      }.to raise_error(ArgumentError)
    end
  end
end 