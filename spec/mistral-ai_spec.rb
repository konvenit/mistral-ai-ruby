# frozen_string_literal: true

RSpec.describe MistralAI do
  it "has a version number" do
    expect(MistralAI::VERSION).not_to be_nil
  end

  describe ".configuration" do
    it "returns a configuration instance" do
      expect(described_class.configuration).to be_a(MistralAI::Configuration)
    end

    it "memoizes the configuration" do
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to be(config2)
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class.configuration)
    end

    it "allows setting configuration values" do
      described_class.configure do |config|
        config.api_key = "test-key"
        config.timeout = 60
      end

      expect(described_class.configuration.api_key).to eq("test-key")
      expect(described_class.configuration.timeout).to eq(60)
    end
  end

  describe ".client" do
    it "creates a client with global configuration" do
      described_class.configure { |config| config.api_key = "global-key" }
      client = described_class.client

      expect(client).to be_a(MistralAI::Client)
      expect(client.configuration.api_key).to eq("global-key")
    end

    it "overrides global configuration with provided api_key" do
      described_class.configure { |config| config.api_key = "global-key" }
      client = described_class.client(api_key: "override-key")

      expect(client.configuration.api_key).to eq("override-key")
    end
  end
end
