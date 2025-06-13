# frozen_string_literal: true

require "faraday"
require "json"
require "base64"
require_relative "exceptions"

module MistralAI
  module MCP
    # OAuth2 authorization server metadata
    class AuthorizationServerMetadata
      attr_accessor :authorization_endpoint, :token_endpoint, :refresh_endpoint,
                    :registration_endpoint, :introspection_endpoint, :revocation_endpoint

      def initialize(data = {})
        @authorization_endpoint = data["authorization_endpoint"]
        @token_endpoint = data["token_endpoint"] 
        @refresh_endpoint = data["refresh_endpoint"]
        @registration_endpoint = data["registration_endpoint"]
        @introspection_endpoint = data["introspection_endpoint"]
        @revocation_endpoint = data["revocation_endpoint"]
      end

      def validate!
        raise MCPAuthException, "Missing authorization_endpoint" unless @authorization_endpoint
        raise MCPAuthException, "Missing token_endpoint" unless @token_endpoint
      end

      def to_h
        {
          "authorization_endpoint" => @authorization_endpoint,
          "token_endpoint" => @token_endpoint,
          "refresh_endpoint" => @refresh_endpoint,
          "registration_endpoint" => @registration_endpoint,
          "introspection_endpoint" => @introspection_endpoint,
          "revocation_endpoint" => @revocation_endpoint
        }.compact
      end
    end

    # OAuth2 parameters for MCP authentication
    class OAuthParams
      attr_accessor :client_id, :client_secret, :scheme

      def initialize(client_id:, client_secret:, scheme:)
        @client_id = client_id
        @client_secret = client_secret
        @scheme = scheme
      end

      def to_h
        {
          client_id: @client_id,
          client_secret: @client_secret,
          scheme: @scheme.to_h
        }
      end
    end

    # OAuth2 token structure
    class OAuth2Token
      attr_accessor :access_token, :token_type, :expires_in, :refresh_token, :scope

      def initialize(data = {})
        @access_token = data["access_token"] || data[:access_token]
        @token_type = data["token_type"] || data[:token_type] || "Bearer"
        @expires_in = data["expires_in"] || data[:expires_in]
        @refresh_token = data["refresh_token"] || data[:refresh_token]
        @scope = data["scope"] || data[:scope]
      end

      def [](key)
        case key.to_s
        when "access_token"
          @access_token
        when "token_type"
          @token_type
        when "expires_in"
          @expires_in
        when "refresh_token"
          @refresh_token
        when "scope"
          @scope
        end
      end

      def to_h
        {
          "access_token" => @access_token,
          "token_type" => @token_type,
          "expires_in" => @expires_in,
          "refresh_token" => @refresh_token,
          "scope" => @scope
        }.compact
      end
    end

    # Async OAuth2 client for MCP authentication
    class AsyncOAuth2Client
      attr_reader :client_id, :client_secret

      def initialize(client_id:, client_secret:)
        @client_id = client_id
        @client_secret = client_secret
        @http_client = Faraday.new do |conn|
          conn.adapter Faraday.default_adapter
          conn.response :json
        end
      end

      def self.from_oauth_params(oauth_params)
        new(
          client_id: oauth_params.client_id,
          client_secret: oauth_params.client_secret
        )
      end

      # Create authorization URL with state
      def create_authorization_url(auth_endpoint, redirect_uri:, state: nil, scope: nil)
        state ||= SecureRandom.hex(16)
        
        params = {
          response_type: "code",
          client_id: @client_id,
          redirect_uri: redirect_uri,
          state: state
        }
        params[:scope] = scope if scope

        query_string = URI.encode_www_form(params)
        auth_url = "#{auth_endpoint}?#{query_string}"
        
        [auth_url, state]
      end

      # Exchange authorization code for token
      def fetch_token(url:, authorization_response:, redirect_uri:, headers: {}, state: nil)
        # Extract code from authorization response
        uri = URI.parse(authorization_response)
        query_params = URI.decode_www_form(uri.query || "")
        code = query_params.find { |k, v| k == "code" }&.last
        
        unless code
          raise MCPAuthException, "No authorization code found in response"
        end

        # Validate state if provided
        if state
          response_state = query_params.find { |k, v| k == "state" }&.last
          unless response_state == state
            raise MCPAuthException, "State mismatch in authorization response"
          end
        end

        token_params = {
          grant_type: "authorization_code",
          code: code,
          redirect_uri: redirect_uri,
          client_id: @client_id,
          client_secret: @client_secret
        }

        response = @http_client.post(url) do |req|
          req.headers = headers
          req.body = URI.encode_www_form(token_params)
        end

        unless response.success?
          raise MCPAuthException, "Token exchange failed: #{response.body}"
        end

        OAuth2Token.new(response.body)
      end

      # Refresh an expired token
      def refresh_token(url:, refresh_token:, headers: {})
        token_params = {
          grant_type: "refresh_token",
          refresh_token: refresh_token,
          client_id: @client_id,
          client_secret: @client_secret
        }

        response = @http_client.post(url) do |req|
          req.headers = headers
          req.body = URI.encode_www_form(token_params)
        end

        unless response.success?
          raise MCPAuthException, "Token refresh failed: #{response.body}"
        end

        OAuth2Token.new(response.body)
      end
    end

    # Get well-known OAuth2 authorization server metadata
    def self.get_well_known_authorization_server_metadata(server_url)
      well_known_url = "#{server_url}/.well-known/oauth-authorization-server"
      
      http_client = Faraday.new do |conn|
        conn.adapter Faraday.default_adapter
        conn.response :json
      end

      response = http_client.get(well_known_url)
      
      if response.success?
        begin
          metadata = AuthorizationServerMetadata.new(response.body)
          metadata.validate!
          metadata
        rescue => e
          puts "Failed to parse OAuth well-known metadata: #{e.message}"
          nil
        end
      else
        puts "Failed to get OAuth well-known metadata from #{server_url}"
        nil
      end
    rescue => e
      puts "Error fetching OAuth metadata: #{e.message}"
      nil
    end

    # Dynamic client registration with MCP server
    def self.dynamic_client_registration(register_endpoint, redirect_url)
      registration_payload = {
        client_name: "MistralSDKClient",
        grant_types: ["authorization_code", "refresh_token"],
        token_endpoint_auth_method: "client_secret_basic",
        response_types: ["code"],
        redirect_uris: [redirect_url]
      }

      http_client = Faraday.new do |conn|
        conn.adapter Faraday.default_adapter
        conn.response :json
      end

      response = http_client.post(register_endpoint) do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(registration_payload)
      end

      unless response.success?
        raise MCPAuthException, 
              "Client registration failed: status=#{response.status}, error=#{response.body}"
      end

      registration_info = response.body
      client_id = registration_info["client_id"]
      client_secret = registration_info["client_secret"]

      unless client_id && client_secret
        raise MCPAuthException, "Registration response missing client credentials"
      end

      [client_id, client_secret]
    rescue => e
      raise MCPAuthException, "Client registration failed: #{e.message}"
    end

    # Build OAuth parameters for MCP server
    def self.build_oauth_params(server_url, redirect_url:)
      metadata = get_well_known_authorization_server_metadata(server_url)
      unless metadata
        raise MCPAuthException, "Could not retrieve OAuth metadata from server"
      end

      if metadata.registration_endpoint
        client_id, client_secret = dynamic_client_registration(
          metadata.registration_endpoint, 
          redirect_url
        )
      else
        raise MCPAuthException, "Server does not support dynamic client registration"
      end

      OAuthParams.new(
        client_id: client_id,
        client_secret: client_secret,
        scheme: metadata
      )
    end
  end
end 