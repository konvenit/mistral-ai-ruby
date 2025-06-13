require_relative '../base_resource'

module MistralAI
  module Resources
    class Embeddings < BaseResource
      def create(model:, input:, output_dimension: nil, output_dtype: nil, **options)
        raise ArgumentError, "input cannot be empty" if input.empty?

        request = {
          model: model,
          input: input,
          output_dimension: output_dimension,
          output_dtype: output_dtype
        }.compact

        response = post('/v1/embeddings', body: request, **options)
        handle_response(response)
      end

      private

      def handle_response(response)
        return response if response.is_a?(Hash)
        case response.code
        when '200'
          JSON.parse(response.body)
        when '422'
          raise APIError.new("Validation error", response.code, response.body)
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