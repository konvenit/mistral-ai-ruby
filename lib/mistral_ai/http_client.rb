# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module MistralAI
  class HTTPClient
    USER_AGENT = "mistral-ai-ruby/#{VERSION}"

    def initialize(configuration)
      @configuration = configuration
      @connection = build_connection
    end

    def get(path, params: {})
      request(:get, path, params: params)
    end

    def post(path, body: nil, stream: false, &block)
      request(:post, path, body: body, stream: stream, &block)
    end

    def request(method, path, params: {}, body: nil, stream: false, &block)
      @configuration.validate!

      response = @connection.send(method) do |req|
        req.url path
        req.params = params if params.any?
        req.body = JSON.generate(body) if body
        req.headers["Accept"] = stream ? "text/event-stream" : "application/json"
        req.options.stream = stream
        req.options.on_data = block if stream && block
      end

      if stream
        # For streaming, the response is handled by the callback
        response
      else
        handle_response(response)
      end
    rescue Faraday::TimeoutError => e
      raise TimeoutError, "Request timed out: #{e.message}"
    rescue Faraday::ConnectionFailed => e
      raise ConnectionError, "Connection failed: #{e.message}"
    rescue StandardError => e
      raise NetworkError, "Network error: #{e.message}"
    end

    private

    def build_connection
      Faraday.new(url: @configuration.base_url) do |conn|
        # Request middleware
        conn.request :authorization, "Bearer", @configuration.api_key!
        conn.request :json

        # Response middleware
        conn.response :json
        conn.response :logger, @configuration.logger if @configuration.logger

        # Retry middleware with exponential backoff
        conn.request :retry,
                     max: @configuration.max_retries,
                     interval: @configuration.retry_delay,
                     interval_randomness: 0.5,
                     backoff_factor: 2,
                     retry_statuses: [429, 500, 502, 503, 504],
                     methods: %w[get post]

        # HTTP adapter
        conn.adapter Faraday.default_adapter

        # Set timeouts
        conn.options.timeout = @configuration.timeout
        conn.options.open_timeout = @configuration.timeout

        # User agent
        conn.headers["User-Agent"] = USER_AGENT
      end
    end

    def handle_response(response)
      case response.status
      when 200..299
        response.body
      when 400
        raise BadRequestError.new(
          error_message(response),
          status_code: response.status,
          response_body: response.body,
          headers: response.headers
        )
      when 401
        raise AuthenticationError.new(
          error_message(response),
          status_code: response.status,
          response_body: response.body,
          headers: response.headers
        )
      when 403
        raise PermissionError.new(
          error_message(response),
          status_code: response.status,
          response_body: response.body,
          headers: response.headers
        )
      when 404
        raise NotFoundError.new(
          error_message(response),
          status_code: response.status,
          response_body: response.body,
          headers: response.headers
        )
      when 429
        raise RateLimitError.new(
          error_message(response),
          status_code: response.status,
          response_body: response.body,
          headers: response.headers
        )
      when 500..599
        raise ServerError.new(
          error_message(response),
          status_code: response.status,
          response_body: response.body,
          headers: response.headers
        )
      else
        raise APIError.new(
          error_message(response),
          status_code: response.status,
          response_body: response.body,
          headers: response.headers
        )
      end
    end

    def error_message(response)
      return "HTTP #{response.status}" unless response.body.is_a?(Hash)

      response.body.dig("error", "message") ||
        response.body["message"] ||
        "HTTP #{response.status}"
    rescue StandardError
      "HTTP #{response.status}"
    end
  end
end
