# frozen_string_literal: true

module MistralAI
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_initializer
        template "mistral-ai.rb", "config/initializers/mistral-ai.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end

      private

      def readme(_path)
        say <<~MESSAGE

          MistralAI has been installed!

          1. Add your API key to config/initializers/mistral-ai.rb
          2. Or set the MISTRAL_API_KEY environment variable

          Usage:
            client = MistralAI::Client.new
            response = client.embeddings.create(model: 'mistral-embed', input: 'Hello!')

        MESSAGE
      end
    end
  end
end
