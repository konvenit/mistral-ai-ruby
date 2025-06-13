#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "dotenv/load"
require "mistral-ai"

# Example usage of MCP STDIO client with Mistral AI
def main
  api_key = ENV.fetch("MISTRAL_API_KEY", nil)
  unless api_key
    puts "Please set MISTRAL_API_KEY environment variable"
    exit 1
  end

  MistralAI::Client.new(api_key: api_key)

  # Create a local MCP server connection (stdio)
  #
  # To run this example, you need a working MCP server. Here are some options:
  #
  # Option 1: Install the filesystem MCP server (recommended for testing)
  # npm install -g @modelcontextprotocol/server-filesystem
  # Then use: "npx", ["@modelcontextprotocol/server-filesystem", "/path/to/directory"]
  #
  # Option 2: Use the official Python MCP SDK to create a simple server
  # pip install mcp
  # Then create a simple server script
  #
  # For this example, we'll try to use the filesystem server if available
  current_dir = Dir.pwd

  # Try multiple possible MCP servers in order of preference
  server_configs = [
    # Filesystem server via npx (most common)
    {
      command: "npx",
      args: ["@modelcontextprotocol/server-filesystem", current_dir],
      name: "filesystem (npx)"
    },
    # Node-based filesystem server
    {
      command: "node",
      args: ["/usr/local/lib/node_modules/@modelcontextprotocol/server-filesystem/dist/index.js", current_dir],
      name: "filesystem (node)"
    },
    # Python echo server (if you have one)
    {
      command: "python3",
      args: [File.expand_path("mcp_echo_server.py", __dir__)],
      name: "echo server"
    }
  ]

  # Find the first available server
  server_params = nil
  server_name = nil

  server_configs.each do |config|
    # Check if the command exists
    next unless system("which #{config[:command]} > /dev/null 2>&1")

    puts "Trying #{config[:name]}..."
    server_params = MistralAI::MCP::StdioServerParameters.new(
      command: config[:command],
      args: config[:args]
    )
    server_name = config[:name]
    break
  end

  unless server_params
    puts "❌ No MCP server found!"
    puts "\nTo run this example, please install an MCP server:"
    puts "npm install -g @modelcontextprotocol/server-filesystem"
    puts "\nOr create a simple echo server using the Python MCP SDK."
    puts "See the README for more information."
    exit 1
  end

  puts "Using MCP server: #{server_name}"

  begin
    # Create MCP client
    mcp_client = MistralAI::MCP::MCPClientSTDIO.new(
      stdio_params: server_params,
      name: server_name
    )

    puts "Initializing MCP session..."
    mcp_client.initialize_session

    puts "Getting available tools..."
    tools = mcp_client.get_tools
    puts "Available tools: #{tools.map { |t| t.dig('function', 'name') }.join(', ')}"

    # Example: Execute a tool (adjust based on your MCP server's tools)
    if tools.any?
      tool_name = tools.first.dig("function", "name")
      puts "\nExecuting tool: #{tool_name}"

      # Adjust arguments based on your tool's requirements
      args = case tool_name
             when "read_file"
               { "path" => "README.md" }
             when "list_directory", "list_files"
               { "path" => "." }
             when "echo"
               { "message" => "Hello from Ruby MCP client!" }
             when "uppercase"
               { "text" => "hello world" }
             when "count_words"
               { "text" => "This is a test sentence with five words" }
             else
               {}
             end

      result = mcp_client.execute_tool(tool_name, args)
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

    # You can now use the tools in chat completions
    # by passing them to the Mistral client
    if tools.any?
      puts "\nUsing MCP tools in chat completion..."

      # Adjust the message based on available tools
      content = if tools.any? { |t| t.dig("function", "name")&.include?("file") }
                  "Help me understand what files are in my current directory"
                else
                  "Please use the available tools to demonstrate their functionality"
                end

      [
        {
          role: "user",
          content: content
        }
      ]

      puts "✅ MCP tools are now ready for use with Mistral AI!"
      puts "Example usage:"
      puts <<~USAGE
        response = client.chat.complete(
          model: "mistral-medium-latest",
          messages: [
            { role: "user", content: "#{content}" }
          ],
          tools: tools,
          tool_choice: "auto"
        )
      USAGE
      puts "\nNote: Actual API calls may take longer when tools are involved."
      puts "The MCP integration is working correctly!"
    end
  rescue MistralAI::MCP::MCPException => e
    puts "MCP Error: #{e.message}"
  rescue StandardError => e
    puts "Error: #{e.message}"
  ensure
    # Clean up
    mcp_client&.close
    puts "\nMCP session closed"
  end
end

main if __FILE__ == $PROGRAM_NAME
