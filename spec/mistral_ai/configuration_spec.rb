# frozen_string_literal: true

RSpec.describe MistralAI::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(config.base_url).to eq("https://api.mistral.ai")
      expect(config.timeout).to eq(30)
      expect(config.max_retries).to eq(3)
      expect(config.retry_delay).to eq(1.0)
      expect(config.logger).to be_nil
    end

    it "reads from environment variables" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("MISTRAL_API_KEY", nil).and_return("env-api-key")
      allow(ENV).to receive(:fetch).with("MISTRAL_BASE_URL", "https://api.mistral.ai").and_return("https://custom.api.url")
      allow(ENV).to receive(:fetch).with("MISTRAL_TIMEOUT", 30).and_return("60")

      config = described_class.new
      expect(config.api_key).to eq("env-api-key")
      expect(config.base_url).to eq("https://custom.api.url")
      expect(config.timeout).to eq(60)
    end
  end

  describe "#api_key!" do
    context "when api_key is set" do
      before { config.api_key = "test-key" }

      it "returns the api_key" do
        expect(config.api_key!).to eq("test-key")
      end
    end

    context "when api_key is not set" do
      before { config.api_key = nil }

      it "raises ConfigurationError" do
        expect { config.api_key! }.to raise_error(
          MistralAI::ConfigurationError,
          /API key is required/
        )
      end
    end
  end

  describe "#validate!" do
    context "when api_key is set" do
      before { config.api_key = "test-key" }

      it "does not raise an error" do
        expect { config.validate! }.not_to raise_error
      end
    end

    context "when api_key is not set" do
      before { config.api_key = nil }

      it "raises ConfigurationError" do
        expect { config.validate! }.to raise_error(MistralAI::ConfigurationError)
      end
    end
  end

  describe "attribute accessors" do
    it "allows setting and getting all attributes" do
      config.api_key = "new-key"
      config.base_url = "https://new.url"
      config.timeout = 120
      config.max_retries = 5
      config.retry_delay = 2.0

      expect(config.api_key).to eq("new-key")
      expect(config.base_url).to eq("https://new.url")
      expect(config.timeout).to eq(120)
      expect(config.max_retries).to eq(5)
      expect(config.retry_delay).to eq(2.0)
    end
  end
end
