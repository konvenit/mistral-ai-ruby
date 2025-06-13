# frozen_string_literal: true

module MistralAI
  class Configuration
    attr_accessor :api_key, :base_url, :timeout, :logger, :max_retries, :retry_delay

    def initialize
      @api_key = ENV.fetch("MISTRAL_API_KEY", nil)
      @base_url = ENV.fetch("MISTRAL_BASE_URL", "https://api.mistral.ai")
      @timeout = ENV.fetch("MISTRAL_TIMEOUT", 30).to_i
      @max_retries = ENV.fetch("MISTRAL_MAX_RETRIES", 3).to_i
      @retry_delay = ENV.fetch("MISTRAL_RETRY_DELAY", 1.0).to_f
      @logger = nil
    end

    def validate!
      api_key || raise(ConfigurationError,
                       "API key is required. Set MISTRAL_API_KEY environment variable or configure manually.")
    end

    def copy(api_key: nil, base_url: nil, timeout: nil, logger: nil, max_retries: nil, retry_delay: nil)
      config = Configuration.new
      config.api_key = api_key || @api_key
      config.base_url = base_url || @base_url
      config.timeout = timeout || @timeout
      config.logger = logger || @logger
      config.max_retries = max_retries || @max_retries
      config.retry_delay = retry_delay || @retry_delay
      config
    end
  end
end
