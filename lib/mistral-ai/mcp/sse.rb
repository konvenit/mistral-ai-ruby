# frozen_string_literal: true

require "faraday"
require "json"
require "uri"
require_relative "base"
require_relative "auth"
require_relative "exceptions"

module MistralAI
  module MCP
    # Parameters for SSE MCP server connection
    class SSEServerParams
      attr_accessor :url, :headers, :timeout, :sse_read_timeout

      def initialize(url:, headers: nil, timeout: 5, sse_read_timeout: 300)
        @url = url
        @headers = headers || {}
        @timeout = timeout
        @sse_read_timeout = sse_read_timeout
      end

      def to_h
        {
          url: @url,
          headers: @headers,
          timeout: @timeout,
          sse_read_timeout: @sse_read_timeout
        }
      end
    end

    # MCP client that uses Server-Sent Events for communication with remote servers
    class MCPClientSSE < MCPClientBase
      attr_reader :sse_params, :oauth_params, :auth_token

      def initialize(sse_params:, name: nil, oauth_params: nil, auth_token: nil)
        super(name: name)
        @sse_params = sse_params
        @oauth_params = oauth_params
        @auth_token = auth_token
        @http_client = nil
        @request_id = 0
      end

      # Get base URL for the MCP server (without /sse suffix)
      def base_url
        @sse_params.url.chomp("/sse")
      end

      # Set OAuth parameters for authentication
      def set_oauth_params(oauth_params)
        @logger.warn "Overriding current OAuth params for #{@name}" if @oauth_params
        @oauth_params = oauth_params
      end

      # Get authorization URL and state for OAuth flow
      def get_auth_url_and_state(redirect_url)
        unless @oauth_params
          raise MCPAuthException,
                "Can't generate an authorization url without oauth_params being set"
        end

        oauth_client = AsyncOAuth2Client.from_oauth_params(@oauth_params)
        oauth_client.create_authorization_url(
          @oauth_params.scheme.authorization_endpoint,
          redirect_uri: redirect_url
        )
      end

      # Exchange authorization response for token
      def get_token_from_auth_response(authorization_response, redirect_url, state)
        unless @oauth_params
          raise MCPAuthException,
                "Can't fetch a token without oauth_params"
        end

        oauth_client = AsyncOAuth2Client.from_oauth_params(@oauth_params)
        oauth_client.fetch_token(
          url: @oauth_params.scheme.token_endpoint,
          authorization_response: authorization_response,
          redirect_uri: redirect_url,
          headers: { "Content-Type" => "application/x-www-form-urlencoded" },
          state: state
        )
      end

      # Refresh an expired token
      def refresh_auth_token
        unless @oauth_params&.scheme&.refresh_endpoint
          raise MCPAuthException,
                "Can't refresh a token without a refresh url"
        end

        unless @auth_token
          raise MCPAuthException,
                "Can't refresh a token without a refresh token"
        end

        oauth_client = AsyncOAuth2Client.from_oauth_params(@oauth_params)
        oauth_token = oauth_client.refresh_token(
          url: @oauth_params.scheme.refresh_endpoint,
          refresh_token: @auth_token["refresh_token"],
          headers: { "Content-Type" => "application/x-www-form-urlencoded" }
        )
        set_auth_token(oauth_token)
      end

      # Set authentication token
      def set_auth_token(token)
        @auth_token = token
      end

      # Check if server requires authentication
      def requires_auth?
        response = http_client.get(@sse_params.url) do |req|
          req.headers.merge!(format_headers)
          req.options.timeout = @sse_params.timeout
        end
        response.status == 401
      rescue StandardError => e
        @logger.warn "Error checking auth requirements: #{e.message}"
        false
      end

      # Initialize SSE session with MCP server
      def initialize_session
        return if @initialized

        begin
          setup_http_client

          # Send initialize request
          initialize_request = {
            jsonrpc: "2.0",
            id: next_request_id,
            method: "initialize",
            params: {
              protocolVersion: "2024-11-05",
              capabilities: {
                tools: {},
                prompts: {}
              },
              clientInfo: {
                name: "mistral-ai-ruby",
                version: "1.0.0"
              }
            }
          }

          response = send_sse_request("initialize", initialize_request["params"])

          raise MCPException, "Failed to initialize MCP session: #{response['error']['message']}" if response["error"]

          @logger.info "SSE MCP session initialized successfully"
          @initialized = true
        rescue StandardError => e
          @logger.error "Failed to initialize SSE MCP session: #{e.message}"
          raise MCPConnectionException, "Failed to initialize SSE MCP session: #{e.message}"
        end
      end

      # Close SSE session
      def close
        @http_client = nil
        @initialized = false
      end

      private

      # Setup HTTP client for SSE communication
      def setup_http_client
        @http_client = Faraday.new do |conn|
          conn.adapter Faraday.default_adapter
          conn.response :json
          conn.request :retry, max: 3, interval: 1
        end
      end

      # Get HTTP client, creating if needed
      def http_client
        @http_client ||= setup_http_client
        @http_client
      end

      # Format headers including authentication
      def format_headers
        headers = @sse_params.headers.dup
        headers["Authorization"] = "Bearer #{@auth_token['access_token']}" if @auth_token
        headers
      end

      # Send RPC method via SSE
      def call_rpc_method(method, params = {})
        send_sse_request(method, params)
      end

      # Send SSE request to MCP server
      def send_sse_request(method, params = {})
        request_payload = {
          jsonrpc: "2.0",
          id: next_request_id,
          method: method,
          params: params
        }

        response = http_client.post(@sse_params.url) do |req|
          req.headers.merge!(format_headers)
          req.headers["Content-Type"] = "application/json"
          req.headers["Accept"] = "application/json"
          req.options.timeout = @sse_params.timeout
          req.body = JSON.generate(request_payload)
        end

        handle_sse_response(response)
      rescue Faraday::UnauthorizedError
        raise MCPAuthException, "Authentication required" if @oauth_params

        raise MCPAuthException, "Authentication required but no auth params provided"
      rescue StandardError => e
        @logger.error "Error sending SSE request: #{e.message}"
        raise MCPConnectionException, "Failed to send SSE request: #{e.message}"
      end

      # Handle SSE response from server
      def handle_sse_response(response)
        unless response.success?
          case response.status
          when 401
            raise MCPAuthException, "Authentication required" if @oauth_params

            raise MCPAuthException, "Authentication required but no auth params provided"

          else
            raise MCPConnectionException, "HTTP #{response.status}: #{response.body}"
          end
        end

        begin
          parsed_response = response.body.is_a?(String) ? JSON.parse(response.body) : response.body

          if parsed_response["error"]
            error_message = parsed_response["error"]["message"] || "Unknown error"
            error_code = parsed_response["error"]["code"]
            raise MCPServerException.new(error_message, error_code)
          end

          parsed_response["result"] || {}
        rescue JSON::ParserError
          @logger.error "Invalid JSON response: #{response.body}"
          raise MCPException, "Invalid JSON response from MCP server"
        end
      end

      # Generate next request ID
      def next_request_id
        @request_id += 1
      end
    end
  end
end
