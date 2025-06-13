# frozen_string_literal: true

module MistralAI
  # Base error class for all MistralAI errors
  class Error < StandardError; end

  # Configuration-related errors
  class ConfigurationError < Error; end

  # HTTP and network-related errors
  class APIError < Error
    attr_reader :status_code, :response_body, :headers

    def initialize(message = nil, status_code: nil, response_body: nil, headers: nil)
      super(message)
      @status_code = status_code
      @response_body = response_body
      @headers = headers
    end
  end

  class ValidationError < APIError; end

  # Specific API error types
  class AuthenticationError < APIError; end # 401
  class PermissionError < APIError; end     # 403
  class NotFoundError < APIError; end       # 404
  class RateLimitError < APIError; end      # 429
  class ServerError < APIError; end         # 5xx
  class BadRequestError < APIError; end     # 400

  # Network and connection errors
  class NetworkError < Error; end
  class TimeoutError < NetworkError; end
  class ConnectionError < NetworkError; end

  # JSON parsing errors
  class ParseError < Error; end

  # Streaming errors
  class StreamingError < Error; end
end
