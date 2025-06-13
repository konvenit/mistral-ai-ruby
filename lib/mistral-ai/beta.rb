# frozen_string_literal: true

require_relative "resources/beta_agents"

module MistralAI
  class Beta
    attr_reader :agents

    def initialize(client)
      @client = client
      @agents = Resources::BetaAgents.new(client)
    end
  end
end
