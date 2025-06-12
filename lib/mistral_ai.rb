# frozen_string_literal: true

require_relative "mistral_ai/version"
require_relative "mistral_ai/configuration"
require_relative "mistral_ai/errors"
require_relative "mistral_ai/http_client"
require_relative "mistral_ai/base_resource"
require_relative "mistral_ai/client"

module MistralAI
  class << self
    # Global configuration
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    # Convenience method to create a client with global config
    def client(api_key: nil)
      Client.new(api_key: api_key || configuration.api_key)
    end
  end
end
