# frozen_string_literal: true

require_relative "http_client"

module MistralAI
  class BaseResource
    def initialize(client)
      @client = client
      @http_client = client.http_client
    end

    protected

    attr_reader :client, :http_client

    def get(path, params: {})
      http_client.get(path, params: params)
    end

    def post(path, body: nil, stream: false, &block)
      http_client.post(path, body: body, stream: stream, &block)
    end
  end
end
