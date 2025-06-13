# frozen_string_literal: true

RSpec.describe MistralAI::Client do
  describe "#initialize" do
    it "creates a client with default configuration" do
      client = described_class.new(api_key: "test-key")

      expect(client.configuration).to be_a(MistralAI::Configuration)
      expect(client.configuration.api_key).to eq("test-key")
      expect(client.http_client).to be_a(MistralAI::HTTPClient)
    end

    it "allows overriding configuration values" do
      client = described_class.new(
        api_key: "test-key",
        base_url: "https://custom.url",
        timeout: 60,
        max_retries: 5,
        retry_delay: 2.0
      )

      expect(client.configuration.api_key).to eq("test-key")
      expect(client.configuration.base_url).to eq("https://custom.url")
      expect(client.configuration.timeout).to eq(60)
      expect(client.configuration.max_retries).to eq(5)
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

    it "memoizes resource instances" do
      expect(client.chat).to be(client.chat)
      expect(client.agents).to be(client.agents)
    end
  end

  describe "resource initialization" do
    let(:client) { described_class.new(api_key: "test-key") }

    it "passes client instance to resources" do
      # This tests that resources can access the client
      expect { client.chat.send(:client) }.not_to raise_error
      expect { client.agents.send(:client) }.not_to raise_error
    end
  end
end
