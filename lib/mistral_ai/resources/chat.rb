# frozen_string_literal: true

require_relative "../base_resource"

module MistralAI
  module Resources
    class Chat < BaseResource
      # Phase 2: Implementation will be added here
      # - complete: Synchronous chat completion
      # - stream: Streaming chat completion
      # - Message types and validation
      # - Response objects

      def complete(model:, messages:, **options)
        # TODO: Phase 2 implementation
        raise NotImplementedError, "Chat completion will be implemented in Phase 2"
      end

      def stream(model:, messages:, **options, &block)
        # TODO: Phase 2 implementation
        raise NotImplementedError, "Chat streaming will be implemented in Phase 2"
      end
    end
  end
end
