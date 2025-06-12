require_relative '../base_resource'

module MistralAI
  module Resources
    class OCR < BaseResource
      def process(model:, document:, id: nil, pages: nil, include_image_base64: nil,
                 image_limit: nil, image_min_size: nil, bbox_annotation_format: nil,
                 document_annotation_format: nil, **options)
        request = {
          model: model,
          document: document,
          id: id,
          pages: pages,
          include_image_base64: include_image_base64,
          image_limit: image_limit,
          image_min_size: image_min_size,
          bbox_annotation_format: bbox_annotation_format,
          document_annotation_format: document_annotation_format
        }.compact

        response = post('/v1/ocr', body: request, **options)
        handle_response(response)
      end

      def process_async(model:, document:, id: nil, pages: nil, include_image_base64: nil,
                       image_limit: nil, image_min_size: nil, bbox_annotation_format: nil,
                       document_annotation_format: nil, **options)
        request = {
          model: model,
          document: document,
          id: id,
          pages: pages,
          include_image_base64: include_image_base64,
          image_limit: image_limit,
          image_min_size: image_min_size,
          bbox_annotation_format: bbox_annotation_format,
          document_annotation_format: document_annotation_format
        }.compact

        response = post_async('/v1/ocr', body: request, **options)
        handle_response(response)
      end

      private

      def handle_response(response)
        return response if response.is_a?(Hash)
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