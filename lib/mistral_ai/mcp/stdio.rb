# frozen_string_literal: true

require "open3"
require "json"
require_relative "base"
require_relative "exceptions"

module MistralAI
  module MCP
    # Parameters for STDIO MCP server
    class StdioServerParameters
      attr_accessor :command, :args, :env

      def initialize(command:, args: [], env: nil)
        @command = command
        @args = args || []
        @env = env
      end

      def to_h
        {
          command: @command,
          args: @args,
          env: @env
        }
      end
    end

    # MCP client that uses stdio for communication with local servers
    class MCPClientSTDIO < MCPClientBase
      attr_reader :stdio_params

      def initialize(stdio_params:, name: nil)
        super(name: name)
        @stdio_params = stdio_params
        @stdin = nil
        @stdout = nil
        @stderr = nil
        @wait_thread = nil
        @request_id = 0
      end

      # Initialize the stdio session with the MCP server
      def initialize_session
        return if @initialized

        begin
          @stdin, @stdout, @stderr, @wait_thread = Open3.popen3(
            @stdio_params.env || {},
            @stdio_params.command,
            *@stdio_params.args
          )

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

          send_request(initialize_request)
          response = read_response

          if response["error"]
            raise MCPException, "Failed to initialize MCP session: #{response['error']['message']}"
          end

          @logger.info "STDIO MCP session initialized successfully"
          @initialized = true
        rescue => e
          @logger.error "Failed to initialize STDIO MCP session: #{e.message}"
          close
          raise MCPConnectionException, "Failed to initialize STDIO MCP session: #{e.message}"
        end
      end

      # Close the stdio session
      def close
        return unless @stdin || @stdout || @stderr

        begin
          @stdin&.close
          @stdout&.close  
          @stderr&.close
          @wait_thread&.kill if @wait_thread&.alive?
        rescue => e
          @logger.warn "Error closing STDIO MCP session: #{e.message}"
        ensure
          @stdin = nil
          @stdout = nil
          @stderr = nil
          @wait_thread = nil
          @initialized = false
        end
      end

      private

      # Send JSON-RPC request to MCP server via stdio
      def call_rpc_method(method, params = {})
        request = {
          jsonrpc: "2.0",
          id: next_request_id,
          method: method,
          params: params
        }

        send_request(request)
        response = read_response

        if response["error"]
          error_message = response["error"]["message"] || "Unknown error"
          error_code = response["error"]["code"]
          raise MCPServerException.new(error_message, error_code)
        end

        response["result"] || {}
      end

      # Send a JSON-RPC request
      def send_request(request)
        json_data = JSON.generate(request)
        @logger.debug "Sending STDIO request: #{json_data}"
        @stdin.puts(json_data)
        @stdin.flush
      rescue => e
        @logger.error "Error sending STDIO request: #{e.message}"
        raise MCPConnectionException, "Failed to send request: #{e.message}"
      end

      # Read a JSON-RPC response
      def read_response
        line = @stdout.readline.strip
        @logger.debug "Received STDIO response: #{line}"
        JSON.parse(line)
      rescue EOFError
        raise MCPConnectionException, "Connection closed by MCP server"
      rescue JSON::ParserError => e
        @logger.error "Invalid JSON response: #{line}"
        raise MCPException, "Invalid JSON response from MCP server"
      rescue => e
        @logger.error "Error reading STDIO response: #{e.message}"
        raise MCPConnectionException, "Failed to read response: #{e.message}"
      end

      # Generate next request ID
      def next_request_id
        @request_id += 1
      end
    end
  end
end 