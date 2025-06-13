# frozen_string_literal: true

module MistralAI
  class Railtie < Rails::Railtie
    config.mistral_ai = ActiveSupport::OrderedOptions.new

    initializer "mistral_ai.configure" do |app|
      MistralAI.configure do |config|
        config.api_key = app.config.mistral_ai.api_key if app.config.mistral_ai.api_key
        config.base_url = app.config.mistral_ai.base_url if app.config.mistral_ai.base_url
        config.timeout = app.config.mistral_ai.timeout if app.config.mistral_ai.timeout
        config.logger = app.config.mistral_ai.logger if app.config.mistral_ai.logger
        config.max_retries = app.config.mistral_ai.max_retries if app.config.mistral_ai.max_retries
        config.retry_delay = app.config.mistral_ai.retry_delay if app.config.mistral_ai.retry_delay
      end
    end
  end
end
