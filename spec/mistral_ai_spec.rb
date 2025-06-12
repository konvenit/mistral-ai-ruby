# frozen_string_literal: true

RSpec.describe MistralAI do
  it "has a version number" do
    expect(MistralAI::VERSION).not_to be_nil
  end

  describe ".configuration" do
    it "returns a configuration instance" do
      expect(MistralAI.configuration).to be_a(MistralAI::Configuration)
    end

    it "memoizes the configuration" do
      config1 = MistralAI.configuration
      config2 = MistralAI.configuration
      expect(config1).to be(config2)
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      expect { |b| MistralAI.configure(&b) }.to yield_with_args(MistralAI.configuration)
    end

    it "allows setting configuration values" do
      MistralAI.configure do |config|
        config.api_key = "test-key"
        config.timeout = 60
      end

      expect(MistralAI.configuration.api_key).to eq("test-key")
      expect(MistralAI.configuration.timeout).to eq(60)
    end
  end

  describe ".client" do
    it "creates a client with global configuration" do
      MistralAI.configure { |config| config.api_key = "global-key" }
      client = MistralAI.client

      expect(client).to be_a(MistralAI::Client)
      expect(client.configuration.api_key).to eq("global-key")
    end

    it "overrides global configuration with provided api_key" do
      MistralAI.configure { |config| config.api_key = "global-key" }
      client = MistralAI.client(api_key: "override-key")

      expect(client.configuration.api_key).to eq("override-key")
    end
  end
end
