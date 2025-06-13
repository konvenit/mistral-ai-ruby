# frozen_string_literal: true

require "json"
require_relative "responses"

module MistralAI
  module Streaming
    # Parser for Server-Sent Events (SSE) streaming responses
    class SSEParser
      DONE_MESSAGE = "[DONE]"
      DATA_PREFIX = "data: "

      def initialize(&block)
        @callback = block
        @buffer = ""
      end

      # Parse a chunk of SSE data
      def parse(chunk)
        @buffer += chunk

        # Process complete lines
        while @buffer.include?("\n")
          line, @buffer = @buffer.split("\n", 2)
          process_line(line.strip)
        end
      end

      # Signal that streaming is complete
      def finish
        # Process any remaining buffer content
        process_line(@buffer.strip) unless @buffer.strip.empty?
        @buffer = ""
      end

      private

      def process_line(line)
        return if line.empty? || !line.start_with?(DATA_PREFIX)

        data = line[DATA_PREFIX.length..].strip
        return if data.empty?

        # Check for stream termination
        return if data == DONE_MESSAGE

        begin
          json_data = JSON.parse(data)
          response = Responses::ChatStreamResponse.new(json_data)
          @callback&.call(response)
        rescue JSON::ParserError => e
          # Log error but continue processing
          warn "Failed to parse SSE data: #{e.message}" if $DEBUG
        end
      end
    end

    # Streaming response handler
    class StreamHandler
      def initialize(http_client)
        @http_client = http_client
      end

      # Handle streaming request with callback
      def stream(path:, body:, &block)
        parser = SSEParser.new(&block)

        response = @http_client.post(path, body: body, stream: true) do |chunk|
          parser.parse(chunk)
        end

        parser.finish
        response
      end
    end

    # Enumerable interface for streaming responses
    class StreamEnumerator
      include Enumerable

      def initialize(http_client, path:, body:)
        @http_client = http_client
        @path = path
        @body = body
      end

      def each(&block)
        return enum_for(:each) unless block

        handler = StreamHandler.new(@http_client)
        handler.stream(path: @path, body: @body, &block)
      end

      # Collect all streaming responses into an array
      def to_a
        responses = []
        each { |response| responses << response }
        responses
      end

      # Get the first response
      def first
        each { |response| return response }
        nil
      end

      # Get the last response (consumes entire stream)
      def last
        last_response = nil
        each { |response| last_response = response }
        last_response
      end
    end
  end
end
