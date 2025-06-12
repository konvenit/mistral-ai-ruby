#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "dotenv/load"
require "mistral_ai"
require "webrick"

# Example usage of MCP SSE client with OAuth authentication
def main
  api_key = ENV["MISTRAL_API_KEY"]
  unless api_key
    puts "Please set MISTRAL_API_KEY environment variable"
    exit 1
  end

  client = MistralAI::Client.new(api_key: api_key)

  # Example remote MCP server URL (adjust for your server)
  # Note: This example uses Linear's MCP server which requires OAuth
  server_url = ENV["MCP_SSE_SERVER_URL"] || "https://mcp.linear.app/sse"
  
  puts "This example demonstrates SSE MCP client with OAuth authentication"
  puts "Server URL: #{server_url}"
  puts "ℹ️  This example requires a working MCP SSE server with OAuth."
  puts "To test with a different server, set MCP_SSE_SERVER_URL environment variable."
  
  # Set up SSE parameters
  sse_params = MistralAI::MCP::SSEServerParams.new(
    url: server_url,
    timeout: 10,
    sse_read_timeout: 300
  )

  begin
    # Create MCP SSE client
    puts "Creating MCP SSE client..."
    mcp_client = MistralAI::MCP::MCPClientSSE.new(
      sse_params: sse_params,
      name: "remote_mcp_server"
    )

    # Check if authentication is required
    puts "Checking if authentication is required..."
    if mcp_client.requires_auth?
      puts "✅ Authentication required for MCP server"
      
      # Set up OAuth callback server
      callback_received = false
      auth_response = nil
      
      callback_server = WEBrick::HTTPServer.new(
        Port: 8080,
        Logger: WEBrick::Log.new("/dev/null"),
        AccessLog: []
      )

      callback_server.mount_proc "/callback" do |req, res|
        auth_response = req.request_uri.to_s
        callback_received = true
        res.body = "Authorization received! You can close this window."
        callback_server.shutdown
      end

      # Start callback server in background
      Thread.new { callback_server.start }

      redirect_url = "http://localhost:8080/callback"

      # Build OAuth parameters
      puts "Setting up OAuth configuration..."
      oauth_params = MistralAI::MCP.build_oauth_params(
        mcp_client.base_url, 
        redirect_url: redirect_url
      )
      mcp_client.set_oauth_params(oauth_params)

      # Get authorization URL
      auth_url, state = mcp_client.get_auth_url_and_state(redirect_url)
      puts "Please visit this URL to authorize the application:"
      puts auth_url

      # Open browser automatically (commented out since we don't have launchy)
      # Launchy.open(auth_url)
      puts "You can also copy and paste this URL in your browser."

      # Wait for callback with timeout
      puts "Waiting for authorization (30 second timeout)..."
      timeout_counter = 0
      while !callback_received && timeout_counter < 30
        sleep 1
        timeout_counter += 1
      end
      
      unless callback_received
        puts "❌ Authorization timeout. OAuth flow was not completed within 30 seconds."
        puts "This is expected if you don't have Linear access or didn't complete the OAuth flow."
        callback_server.shutdown
        raise MistralAI::MCP::MCPAuthException, "OAuth authorization timeout"
      end

      # Exchange code for token
      puts "Exchanging authorization code for token..."
      token = mcp_client.get_token_from_auth_response(
        auth_response, 
        redirect_url, 
        state
      )
      mcp_client.set_auth_token(token)
      puts "✅ Authentication successful!"
    else
      puts "ℹ️  No authentication required for this server"
    end

    # Initialize session
    puts "Initializing MCP session..."
    mcp_client.initialize_session
    puts "✅ MCP session initialized"

    puts "Getting available tools..."
    tools = mcp_client.get_tools
    puts "Available tools: #{tools.map { |t| t.dig('function', 'name') }.join(', ')}"

    # Example: Execute a tool (adjust based on your MCP server's tools)
    if tools.any?
      tool_name = tools.first.dig("function", "name")
      puts "\nExecuting tool: #{tool_name}"
      
      # Adjust arguments based on your tool's requirements
      result = mcp_client.execute_tool(tool_name, {})
      puts "Tool result: #{result}"
    end

    # Example: List system prompts (not all servers support prompts)
    puts "\nListing system prompts..."
    begin
      prompts = mcp_client.list_system_prompts
      puts "Available prompts: #{prompts}"
    rescue MistralAI::MCP::MCPException => e
      puts "Note: This server doesn't support prompts (#{e.message})"
    end

    # Use tools in chat completion
    if tools.any?
      puts "\nUsing MCP tools in chat completion..."
      
      messages = [
        {
          role: "user",
          content: "Tell me about my Linear workspace and projects"
        }
      ]

      puts "✅ MCP tools are now ready for use with Mistral AI!"
      puts "Example usage:"
      puts <<~USAGE
        response = client.chat.complete(
          model: "mistral-medium-latest",
          messages: [
            { role: "user", content: "Tell me about my Linear workspace and projects" }
          ],
          tools: tools,
          tool_choice: "auto"
        )
      USAGE
      puts "\nNote: Actual API calls may take longer when tools are involved."
      puts "The MCP SSE integration is working correctly!"
    end

  rescue MistralAI::MCP::MCPAuthException => e
    puts "❌ Authentication Error: #{e.message}"
    puts "Make sure the MCP server supports OAuth and is properly configured"
  rescue MistralAI::MCP::MCPConnectionException => e
    puts "❌ Connection Error: #{e.message}"
    puts "This could mean:"
    puts "  - The server URL is incorrect"
    puts "  - The server is not running"
    puts "  - Network connectivity issues"
    puts "  - The server doesn't support SSE transport"
  rescue MistralAI::MCP::MCPException => e
    puts "❌ MCP Error: #{e.message}"
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => e
    puts "❌ Network Error: #{e.message}"
    puts "Could not connect to the MCP server. Please check:"
    puts "  - Server URL: #{server_url}"
    puts "  - Network connectivity"
    puts "  - Server availability"
  rescue => e
    puts "❌ Unexpected Error: #{e.message}"
    puts "Error class: #{e.class}"
    puts "Backtrace:"
    puts e.backtrace.first(5)
  ensure
    # Clean up
    mcp_client&.close
    puts "\nMCP session closed"
  end
end

if __FILE__ == $0
  main
end 