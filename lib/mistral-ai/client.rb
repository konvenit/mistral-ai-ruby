# frozen_string_literal: true

require_relative "configuration"
require_relative "http_client"
require_relative "resources/chat"
require_relative "resources/agents"
require_relative "resources/embeddings"
require_relative "resources/fine_tuning"
require_relative "resources/ocr"
require_relative "beta"

module MistralAI
  class Client
    attr_reader :configuration, :http_client, :chat, :agents, :embeddings, :fine_tuning, :ocr, :beta

    def initialize(api_key: nil, base_url: nil, timeout: nil, logger: nil, max_retries: nil, retry_delay: nil)
      @configuration = Configuration.new
      @configuration.api_key = api_key if api_key
      @configuration.base_url = base_url if base_url
      @configuration.timeout = timeout if timeout
      @configuration.logger = logger if logger
      @configuration.max_retries = max_retries if max_retries
      @configuration.retry_delay = retry_delay if retry_delay

      @http_client = HTTPClient.new(@configuration)
      @chat = Resources::Chat.new(self)
      @agents = Resources::Agents.new(self)
      @embeddings = Resources::Embeddings.new(self)
      @fine_tuning = Resources::FineTuning.new(self)
      @ocr = Resources::OCR.new(self)
      @beta = Beta.new(self)
    end
  end
end
