# frozen_string_literal: true

require_relative '../base_resource'

module MistralAI
  module Resources
    class Jobs < BaseResource
      def list(**options)
        response = get('/v1/fine-tuning/jobs', **options)
        handle_response(response)
      end

      def create(model:, training_file:, hyperparameters: nil, **options)
        request = {
          model: model,
          training_file: training_file,
          hyperparameters: hyperparameters
        }.compact

        response = post('/v1/fine-tuning/jobs', body: request, **options)
        handle_response(response)
      end

      def retrieve(job_id:, **options)
        response = get("/v1/fine-tuning/jobs/#{job_id}", **options)
        handle_response(response)
      end

      def cancel(job_id:, **options)
        response = post("/v1/fine-tuning/jobs/#{job_id}/cancel", body: {}, **options)
        handle_response(response)
      end

      private

      def handle_response(response)
        case response.code
        when '200'
          JSON.parse(response.body)
        when '422'
          raise ValidationError.new(JSON.parse(response.body))
        when /^[45]/
          raise APIError.new("API error occurred", response.code, response.body)
        else
          raise APIError.new(
            "Unexpected response received (code: #{response.code}, type: #{response.content_type})",
            response.code,
            response.body
          )
        end
      end
    end
  end
end 