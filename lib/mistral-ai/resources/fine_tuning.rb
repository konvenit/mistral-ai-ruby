# frozen_string_literal: true

require_relative "../base_resource"
require_relative "jobs"

module MistralAI
  module Resources
    class FineTuning < BaseResource
      attr_reader :jobs

      def initialize(config)
        super
        @jobs = Jobs.new(config)
      end
    end
  end
end
