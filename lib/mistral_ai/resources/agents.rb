# frozen_string_literal: true

require_relative "../base_resource"

module MistralAI
  module Resources
    class Agents < BaseResource
      # Phase 3: Implementation will be added here
      # - complete: Agent completion with agent_id
      # - stream: Streaming agent completion
      # - Similar interface to chat but with agent_id parameter

      def complete(agent_id:, messages:, **options)
        # TODO: Phase 3 implementation
        raise NotImplementedError, "Agent completion will be implemented in Phase 3"
      end

      def stream(agent_id:, messages:, **options, &block)
        # TODO: Phase 3 implementation
        raise NotImplementedError, "Agent streaming will be implemented in Phase 3"
      end
    end
  end
end
