# frozen_string_literal: true

RSpec.describe MistralAI::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default base_url" do
      expect(config.base_url).to eq("https://api.mistral.ai")
    end

    it "sets default timeout" do
      expect(config.timeout).to eq(30)
    end

    it "sets default max_retries" do
      expect(config.max_retries).to eq(3)
    end

    it "sets default retry_delay" do
      expect(config.retry_delay).to eq(1.0)
    end

    it "sets default logger to nil" do
      expect(config.logger).to be_nil
    end

    it "reads api_key from environment variables" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("MISTRAL_API_KEY", nil).and_return("env-api-key")

      config = described_class.new
      expect(config.api_key).to eq("env-api-key")
    end

    it "reads base_url from environment variables" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("MISTRAL_BASE_URL", "https://api.mistral.ai").and_return("https://custom.api.url")

      config = described_class.new
      expect(config.base_url).to eq("https://custom.api.url")
    end

    it "reads timeout from environment variables" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("MISTRAL_TIMEOUT", 30).and_return("60")

      config = described_class.new
      expect(config.timeout).to eq(60)
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
    it "allows setting and getting api_key" do
      config.api_key = "new-key"

      expect(config.api_key).to eq("new-key")
    end

    it "allows setting and getting base_url" do
      config.base_url = "https://new.url"

      expect(config.base_url).to eq("https://new.url")
    end

    it "allows setting and getting timeout" do
      config.timeout = 120

      expect(config.timeout).to eq(120)
    end

    it "allows setting and getting max_retries" do
      config.max_retries = 5

      expect(config.max_retries).to eq(5)
    end

    it "allows setting and getting retry_delay" do
      config.retry_delay = 2.0

      expect(config.retry_delay).to eq(2.0)
    end
  end
end
