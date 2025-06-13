# frozen_string_literal: true

RSpec.describe MistralAI::Resources::Agents do
  let(:configuration) { MistralAI::Configuration.new }
  let(:http_client) { instance_double(MistralAI::HTTPClient) }
  let(:client) { instance_double(MistralAI::Client, http_client: http_client) }
  let(:agents_resource) { described_class.new(client) }

  describe "#complete" do
    let(:agent_id) { "agent_123" }
    let(:messages) do
      [
        { role: "system", content: "You are a helpful assistant." },
        { role: "user", content: "Analyze this data" }
      ]
    end

    let(:successful_response) do
      {
        "id" => "agentcmpl-456",
        "object" => "chat.completion",
        "created" => 1677652288,
        "model" => "mistral-small-latest",
        "choices" => [
          {
            "index" => 0,
            "message" => {
              "role" => "assistant",
              "content" => "I'll analyze the data for you."
            },
            "finish_reason" => "stop"
          }
        ],
        "usage" => {
          "prompt_tokens" => 15,
          "completion_tokens" => 12,
          "total_tokens" => 27
        }
      }
    end

    before do
      allow(agents_resource).to receive(:post).and_return(successful_response)
    end

    it "makes a successful agent completion request" do
      response = agents_resource.complete(
        agent_id: agent_id,
        messages: messages
      )

      expect(response).to be_a(MistralAI::Responses::ChatResponse)
      expect(response.id).to eq("agentcmpl-456")
      expect(response.content).to eq("I'll analyze the data for you.")
      expect(response.usage.total_tokens).to eq(27)
    end

    it "sends correct request body with agent_id" do
      expected_body = {
        agent_id: agent_id,
        messages: [
          { role: "system", content: "You are a helpful assistant." },
          { role: "user", content: "Analyze this data" }
        ],
        stream: false
      }

      expect(agents_resource).to receive(:post).with(
        "/v1/agents/completions",
        body: expected_body
      ).and_return(successful_response)

      agents_resource.complete(
        agent_id: agent_id,
        messages: messages
      )
    end

    it "includes optional parameters in request" do
      expected_body = {
        agent_id: agent_id,
        messages: [
          { role: "user", content: "Hello" }
        ],
        stream: false,
        temperature: 0.7,
        max_tokens: 150,
        top_p: 0.9
      }

      expect(agents_resource).to receive(:post).with(
        "/v1/agents/completions",
        body: expected_body
      ).and_return(successful_response)

      agents_resource.complete(
        agent_id: agent_id,
        messages: [{ role: "user", content: "Hello" }],
        temperature: 0.7,
        max_tokens: 150,
        top_p: 0.9
      )
    end

    context "agent_id validation" do
      it "raises error when agent_id is nil" do
        expect {
          agents_resource.complete(agent_id: nil, messages: messages)
        }.to raise_error(ArgumentError, "agent_id must be a string")
      end

      it "raises error when agent_id is empty string" do
        expect {
          agents_resource.complete(agent_id: "", messages: messages)
        }.to raise_error(ArgumentError, "agent_id is required and cannot be empty")
      end

      it "raises error when agent_id is not a string" do
        expect {
          agents_resource.complete(agent_id: 123, messages: messages)
        }.to raise_error(ArgumentError, "agent_id must be a string")
      end
    end

    context "tool calling support" do
      let(:tools) do
        [
          {
            type: "function",
            function: {
              name: "get_weather",
              description: "Get weather information",
              parameters: {
                type: "object",
                properties: {
                  location: { type: "string" }
                }
              }
            }
          }
        ]
      end

      it "includes tools in request body" do
        expected_body = {
          agent_id: agent_id,
          messages: messages.map { |m| { role: m[:role], content: m[:content] } },
          stream: false,
          tools: tools,
          tool_choice: "auto"
        }

        expect(agents_resource).to receive(:post).with(
          "/v1/agents/completions",
          body: expected_body
        ).and_return(successful_response)

        agents_resource.complete(
          agent_id: agent_id,
          messages: messages,
          tools: tools,
          tool_choice: "auto"
        )
      end
    end
  end

  describe "#stream" do
    let(:agent_id) { "agent_123" }
    let(:messages) do
      [{ role: "user", content: "Stream me a response" }]
    end

    let(:stream_handler) { instance_double(MistralAI::Streaming::StreamHandler) }

    context "with block" do
      it "creates a stream handler and calls it with block" do
        block = proc { |chunk| puts chunk.content }

        expect(MistralAI::Streaming::StreamHandler).to receive(:new).with(http_client).and_return(stream_handler)
        expect(stream_handler).to receive(:stream).with(
          path: "/v1/agents/completions",
          body: {
            agent_id: agent_id,
            messages: [{ role: "user", content: "Stream me a response" }],
            stream: true
          }
        )

        agents_resource.stream(
          agent_id: agent_id,
          messages: messages,
          &block
        )
      end

      it "includes optional parameters in streaming request" do
        block = proc { |chunk| puts chunk.content }

        expect(MistralAI::Streaming::StreamHandler).to receive(:new).with(http_client).and_return(stream_handler)
        expect(stream_handler).to receive(:stream).with(
          path: "/v1/agents/completions",
          body: {
            agent_id: agent_id,
            messages: [{ role: "user", content: "Stream me a response" }],
            stream: true,
            temperature: 0.8,
            max_tokens: 200
          }
        )

        agents_resource.stream(
          agent_id: agent_id,
          messages: messages,
          temperature: 0.8,
          max_tokens: 200,
          &block
        )
      end
    end

    context "without block" do
      it "returns a StreamEnumerator" do
        result = agents_resource.stream(
          agent_id: agent_id,
          messages: messages
        )

        expect(result).to be_a(MistralAI::Streaming::StreamEnumerator)
      end
    end

    context "agent_id validation in streaming" do
      it "raises error when agent_id is nil" do
        expect {
          agents_resource.stream(agent_id: nil, messages: messages)
        }.to raise_error(ArgumentError, "agent_id must be a string")
      end

      it "raises error when agent_id is empty string" do
        expect {
          agents_resource.stream(agent_id: "", messages: messages)
        }.to raise_error(ArgumentError, "agent_id is required and cannot be empty")
      end

      it "raises error when agent_id is not a string" do
        expect {
          agents_resource.stream(agent_id: 123, messages: messages)
        }.to raise_error(ArgumentError, "agent_id must be a string")
      end
    end
  end

  describe "parameter validation" do
    let(:agent_id) { "agent_123" }
    let(:messages) { [{ role: "user", content: "Test" }] }

    context "tools validation" do
      it "validates tools format" do
        invalid_tools = [{ invalid: "format" }]

        expect {
          agents_resource.complete(
            agent_id: agent_id,
            messages: messages,
            tools: invalid_tools
          )
        }.to raise_error(ArgumentError, /Invalid tool format/)
      end

      it "validates tool_choice format" do
        tools = [
          {
            type: "function",
            function: { name: "test_function" }
          }
        ]

        expect {
          agents_resource.complete(
            agent_id: agent_id,
            messages: messages,
            tools: tools,
            tool_choice: "invalid_choice"
          )
        }.to raise_error(ArgumentError, /tool_choice must be/)
      end
    end

    context "response_format validation" do
      it "validates response_format structure" do
        expect {
          agents_resource.complete(
            agent_id: agent_id,
            messages: messages,
            response_format: { invalid: "format" }
          )
        }.to raise_error(ArgumentError, /response_format must be a hash with 'type' key/)
      end

      it "validates response_format type" do
        expect {
          agents_resource.complete(
            agent_id: agent_id,
            messages: messages,
            response_format: { type: "invalid_type" }
          )
        }.to raise_error(ArgumentError, /response_format type must be one of/)
      end
    end
  end

  describe "error handling" do
    let(:agent_id) { "agent_123" }
    let(:messages) { [{ role: "user", content: "Test" }] }

    it "preserves ArgumentError exceptions" do
      expect {
        agents_resource.complete(agent_id: nil, messages: messages)
      }.to raise_error(ArgumentError)
    end

    it "preserves MistralAI::APIError exceptions" do
      api_error = MistralAI::APIError.new("API failed")
      allow(agents_resource).to receive(:post).and_raise(api_error)

      expect {
        agents_resource.complete(agent_id: agent_id, messages: messages)
      }.to raise_error(MistralAI::APIError, "API failed")
    end

    it "wraps other exceptions in MistralAI::APIError" do
      allow(agents_resource).to receive(:post).and_raise(StandardError.new("Unknown error"))

      expect {
        agents_resource.complete(agent_id: agent_id, messages: messages)
      }.to raise_error(MistralAI::APIError, "Agent completion failed: Unknown error")
    end
  end
end 