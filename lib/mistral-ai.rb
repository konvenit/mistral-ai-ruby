# frozen_string_literal: true

require_relative "mistral-ai/version"
require_relative "mistral-ai/configuration"
require_relative "mistral-ai/errors"
require_relative "mistral-ai/http_client"
require_relative "mistral-ai/base_resource"
require_relative "mistral-ai/client"

# Phase 2: Chat API components
require_relative "mistral-ai/messages"
require_relative "mistral-ai/responses"
require_relative "mistral-ai/streaming"

# Phase 4: Advanced Features
require_relative "mistral-ai/tools"
require_relative "mistral-ai/structured_outputs"

# MCP (Model Context Protocol) Support
require_relative "mistral-ai/mcp"

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
