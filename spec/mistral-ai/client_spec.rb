# frozen_string_literal: true

RSpec.describe MistralAI::Client do
  describe "#initialize" do
    it "creates a client with default configuration" do
      client = described_class.new(api_key: "test-key")

      expect(client.configuration).to be_a(MistralAI::Configuration)
    end

    it "sets the api key in configuration" do
      client = described_class.new(api_key: "test-key")

      expect(client.configuration.api_key).to eq("test-key")
    end

    it "creates an http client" do
      client = described_class.new(api_key: "test-key")

      expect(client.http_client).to be_a(MistralAI::HTTPClient)
    end

    it "allows setting api key" do
      client = described_class.new(
        api_key: "test-key",
        base_url: "https://custom.url",
        timeout: 60,
        max_retries: 5,
        retry_delay: 2.0
      )

      expect(client.configuration.api_key).to eq("test-key")
    end

    it "allows setting base url" do
      client = described_class.new(
        api_key: "test-key",
        base_url: "https://custom.url"
      )

      expect(client.configuration.base_url).to eq("https://custom.url")
    end

    it "allows setting timeout" do
      client = described_class.new(
        api_key: "test-key",
        timeout: 60
      )

      expect(client.configuration.timeout).to eq(60)
    end

    it "allows setting max retries" do
      client = described_class.new(
        api_key: "test-key",
        max_retries: 5
      )

      expect(client.configuration.max_retries).to eq(5)
    end

    it "allows setting retry delay" do
      client = described_class.new(
        api_key: "test-key",
        retry_delay: 2.0
      )

      expect(client.configuration.retry_delay).to eq(2.0)
    end

    it "preserves nil values for optional parameters" do
      client = described_class.new(api_key: "test-key")

      expect(client.configuration.logger).to be_nil
    end
  end

  describe "resource access" do
    let(:client) { described_class.new(api_key: "test-key") }

    it "provides access to chat resource" do
      expect(client.chat).to be_a(MistralAI::Resources::Chat)
    end

    it "provides access to agents resource" do
      expect(client.agents).to be_a(MistralAI::Resources::Agents)
    end

    it "memoizes chat resource instances" do
      chat_instance = client.chat
      expect(client.chat).to be(chat_instance)
    end

    it "memoizes agents resource instances" do
      agents_instance = client.agents
      expect(client.agents).to be(agents_instance)
    end
  end

  describe "resource initialization" do
    let(:client) { described_class.new(api_key: "test-key") }

    it "passes client instance to chat resource" do
      expect { client.chat.send(:client) }.not_to raise_error
    end

    it "passes client instance to agents resource" do
      expect { client.agents.send(:client) }.not_to raise_error
    end
  end
end
