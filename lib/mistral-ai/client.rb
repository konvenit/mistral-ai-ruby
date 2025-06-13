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
    attr_reader :api_key, :base_url, :timeout, :logger, :max_retries, :retry_delay
    attr_reader :http_client, :chat, :agents, :embeddings, :fine_tuning, :ocr, :beta

    def initialize(api_key: nil, base_url: nil, timeout: nil, logger: nil, max_retries: nil, retry_delay: nil)
      @api_key = api_key || MistralAI.configuration.api_key
      @base_url = base_url || MistralAI.configuration.base_url
      @timeout = timeout || MistralAI.configuration.timeout
      @logger = logger || MistralAI.configuration.logger
      @max_retries = max_retries || MistralAI.configuration.max_retries
      @retry_delay = retry_delay || MistralAI.configuration.retry_delay

      @http_client = HTTPClient.new(self)
      @chat = Resources::Chat.new(self)
      @agents = Resources::Agents.new(self)
      @embeddings = Resources::Embeddings.new(self)
      @fine_tuning = Resources::FineTuning.new(self)
      @ocr = Resources::OCR.new(self)
      @beta = Beta.new(self)
    end
  end
end
