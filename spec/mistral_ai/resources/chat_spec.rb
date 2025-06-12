# frozen_string_literal: true

RSpec.describe MistralAI::Resources::Chat do
  let(:configuration) { MistralAI::Configuration.new }
  let(:http_client) { instance_double(MistralAI::HTTPClient) }
  let(:client) { instance_double(MistralAI::Client, http_client: http_client) }
  let(:chat_resource) { described_class.new(client) }

  describe "#complete" do
    let(:messages) do
      [
        { role: "system", content: "You are a helpful assistant." },
        { role: "user", content: "Hello, how are you?" }
      ]
    end

    let(:successful_response) do
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
              "content" => "Hello! I'm doing well, thank you for asking."
            },
            "finish_reason" => "stop"
          }
        ],
        "usage" => {
          "prompt_tokens" => 12,
          "completion_tokens" => 15,
          "total_tokens" => 27
        }
      }
    end

    before do
      allow(chat_resource).to receive(:post).and_return(successful_response)
    end

    it "makes a successful chat completion request" do
      response = chat_resource.complete(
        model: "mistral-small-latest",
        messages: messages
      )

      expect(response).to be_a(MistralAI::Responses::ChatResponse)
      expect(response.id).to eq("chatcmpl-123")
      expect(response.content).to eq("Hello! I'm doing well, thank you for asking.")
      expect(response.usage.total_tokens).to eq(27)
    end

    it "sends correct request body" do
      expected_body = {
        model: "mistral-small-latest",
        messages: [
          { role: "system", content: "You are a helpful assistant." },
          { role: "user", content: "Hello, how are you?" }
        ],
        stream: false
      }

      expect(chat_resource).to receive(:post).with(
        "/v1/chat/completions",
        body: expected_body
      ).and_return(successful_response)

      chat_resource.complete(
        model: "mistral-small-latest",
        messages: messages
      )
    end

    it "includes optional parameters in request" do
      expected_body = {
        model: "mistral-small-latest",
        messages: [
          { role: "user", content: "Hello" }
        ],
        stream: false,
        temperature: 0.7,
        max_tokens: 150,
        top_p: 0.9
      }

      expect(chat_resource).to receive(:post).with(
        "/v1/chat/completions",
        body: expected_body
      ).and_return(successful_response)

      chat_resource.complete(
        model: "mistral-small-latest",
        messages: [{ role: "user", content: "Hello" }],
        temperature: 0.7,
        max_tokens: 150,
        top_p: 0.9
      )
    end
  end

  describe "#stream" do
    let(:messages) do
      [{ role: "user", content: "Tell me a story" }]
    end

    let(:stream_handler) { instance_double(MistralAI::Streaming::StreamHandler) }

    context "with block" do
      it "creates a stream handler and calls it with block" do
        block = proc { |chunk| puts chunk.content }

        expect(MistralAI::Streaming::StreamHandler).to receive(:new).with(http_client).and_return(stream_handler)
        expect(stream_handler).to receive(:stream).with(
          path: "/v1/chat/completions",
          body: {
            model: "mistral-small-latest",
            messages: [{ role: "user", content: "Tell me a story" }],
            stream: true
          }
        )

        chat_resource.stream(
          model: "mistral-small-latest",
          messages: messages,
          &block
        )
      end
    end

    context "without block" do
      it "returns a StreamEnumerator" do
        result = chat_resource.stream(
          model: "mistral-small-latest",
          messages: messages
        )

        expect(result).to be_a(MistralAI::Streaming::StreamEnumerator)
      end
    end
  end
end 