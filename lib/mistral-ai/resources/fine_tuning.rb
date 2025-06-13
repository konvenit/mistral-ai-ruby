require_relative '../base_resource'
require_relative 'jobs'

module MistralAI
  module Resources
    class FineTuning < BaseResource
      attr_reader :jobs

      def initialize(config)
        super(config)
        @jobs = Jobs.new(config)
      end
    end
  end
end 