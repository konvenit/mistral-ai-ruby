# frozen_string_literal: true

MistralAI.configure do |config|
  # Your Mistral API key
  config.api_key = ENV.fetch("MISTRAL_API_KEY", nil)

  # Optional: customize base URL
  # config.base_url = 'https://api.mistral.ai'

  # Optional: customize timeout (seconds)
  # config.timeout = 30

  # Optional: customize retry attempts
  # config.max_retries = 3

  # Optional: customize retry delay (seconds)
  # config.retry_delay = 1.0

  # Optional: customize logger
  # config.logger = Rails.logger
end
