# frozen_string_literal: true

require_relative "../errors"

module MistralAI
  module MCP
    # Base class for MCP-related exceptions
    class MCPException < MistralAI::Error
      def initialize(message = nil)
        super(message)
      end
    end

    # Exception raised for authentication errors with an MCP server
    class MCPAuthException < MCPException
      def initialize(message = "Authentication error with MCP server")
        super(message)
      end
    end

    # Exception raised when MCP server is not found or unreachable
    class MCPConnectionException < MCPException
      def initialize(message = "Unable to connect to MCP server")
        super(message)
      end
    end

    # Exception raised when MCP tool is not found
    class MCPToolNotFoundException < MCPException
      def initialize(tool_name)
        super("Tool '#{tool_name}' not found")
      end
    end

    # Exception raised when MCP server returns an error
    class MCPServerException < MCPException
      attr_reader :error_code

      def initialize(message, error_code = nil)
        super(message)
        @error_code = error_code
      end
    end
  end
end 