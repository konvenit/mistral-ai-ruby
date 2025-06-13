# Mistral AI Ruby Client

A Ruby client library for accessing the Mistral AI API, including chat completions, agents, and streaming support.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mistral-ai-ruby'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install mistral-ai-ruby

## Configuration

You can configure the client using environment variables or by setting configuration values directly:

### Environment Variables

```bash
export MISTRAL_API_KEY="your-api-key"
export MISTRAL_BASE_URL="https://api.mistral.ai"  # Optional, defaults to Mistral API
export MISTRAL_TIMEOUT="30"                        # Optional, defaults to 30 seconds
```

### Global Configuration

```ruby
MistralAI.configure do |config|
  config.api_key = "your-api-key"
  config.base_url = "https://api.mistral.ai"
  config.timeout = 30
  config.max_retries = 3
  config.retry_delay = 1.0
end
```

### Client Configuration

```ruby
client = MistralAI::Client.new(
  api_key: "your-api-key",
  base_url: "https://api.mistral.ai",
  timeout: 30
)
```

## Usage

### Quick Start with Global Configuration

```ruby
require 'mistral-ai'

# Configure globally
MistralAI.configure do |config|
  config.api_key = "your-api-key"
end

# Use the global client
client = MistralAI.client

# Chat completion
response = client.chat.complete(
  model: "mistral-small-latest",
  messages: [
    { role: "user", content: "What is the best French cheese?" }
  ]
)

puts response.content
```

### Client Instance

```ruby
require 'mistral-ai'

client = MistralAI::Client.new(api_key: "your-api-key")

# Chat completion
response = client.chat.complete(
  model: "mistral-small-latest", 
  messages: [
    { role: "user", content: "Hello!" }
  ]
)

# Streaming chat
client.chat.stream(
  model: "mistral-small-latest",
  messages: [
    { role: "user", content: "Tell me a story" }
  ]
) do |chunk|
  print chunk.content if chunk.content
end
```

### Agents API

The Agents API allows you to interact with custom agents created in your Mistral account:

```ruby
# Agent completion
response = client.agents.complete(
  agent_id: "agent_abc123",
  messages: [
    { role: "user", content: "Analyze this data" }
  ]
)

puts response.content

# Agent streaming
client.agents.stream(
  agent_id: "agent_abc123",
  messages: [
    { role: "user", content: "Generate a report" }
  ]
) do |chunk|
  print chunk.content if chunk.content
end

# Agent with options
response = client.agents.complete(
  agent_id: "agent_abc123",
  messages: [
    { role: "user", content: "Help me with this task" }
  ],
  temperature: 0.7,
  max_tokens: 500
)

# Agent with tool calling
response = client.agents.complete(
  agent_id: "agent_abc123",
  messages: [
    { role: "user", content: "What's the weather?" }
  ],
  tools: [
    {
      type: "function",
      function: {
        name: "get_weather",
        description: "Get weather information",
        parameters: {
          type: "object",
          properties: {
            location: { type: "string" }
          }
        }
      }
    }
  ],
  tool_choice: "auto"
)
```

## Model Context Protocol (MCP) Support

The Ruby client now includes comprehensive support for the Model Context Protocol (MCP), allowing integration with external tools and services. MCP enables AI assistants to discover and invoke external tools via standardized protocols.

### MCP Features

- **STDIO Transport**: Connect to local MCP servers via standard input/output
- **SSE Transport**: Connect to remote MCP servers via Server-Sent Events
- **OAuth2 Authentication**: Full OAuth2 support for secure remote server access
- **Tool Integration**: Seamlessly integrate MCP tools with Mistral AI chat completions
- **Prompt Management**: Access and execute system prompts from MCP servers

### STDIO MCP Client (Local Servers)

```ruby
require 'mistral-ai'

# Configure MCP server parameters
server_params = MistralAI::MCP::StdioServerParameters.new(
  command: "python",
  args: ["path/to/your/mcp_server.py"],
  env: { "DEBUG" => "true" }
)

# Create MCP client
mcp_client = MistralAI::MCP::MCPClientSTDIO.new(
  stdio_params: server_params,
  name: "filesystem_tools"
)

# Initialize session
mcp_client.initialize_session

# Get available tools
tools = mcp_client.get_tools
puts "Available tools: #{tools.map { |t| t.dig('function', 'name') }.join(', ')}"

# Execute a tool
result = mcp_client.execute_tool("list_files", { "path" => "." })
puts "Tool result: #{result}"

# Use tools in chat completion
client = MistralAI::Client.new(api_key: "your-api-key")

response = client.chat.complete(
  model: "mistral-medium-latest",
  messages: [
    { role: "user", content: "What files are in my current directory?" }
  ],
  tools: tools,
  tool_choice: "auto"
)

# Clean up
mcp_client.close
```

### SSE MCP Client (Remote Servers)

```ruby
require 'mistral-ai'

# Configure SSE server parameters
sse_params = MistralAI::MCP::SSEServerParams.new(
  url: "https://mcp.example.com/sse",
  headers: { "X-API-Key" => "your-api-key" },
  timeout: 10,
  sse_read_timeout: 300
)

# Create SSE MCP client
mcp_client = MistralAI::MCP::MCPClientSSE.new(
  sse_params: sse_params,
  name: "remote_server"
)

# Check if authentication is required
if mcp_client.requires_auth?
  # Set up OAuth2 authentication
  oauth_params = MistralAI::MCP.build_oauth_params(
    mcp_client.base_url,
    redirect_url: "http://localhost:8080/callback"
  )
  mcp_client.set_oauth_params(oauth_params)
  
  # Get authorization URL
  auth_url, state = mcp_client.get_auth_url_and_state(redirect_url)
  puts "Please visit: #{auth_url}"
  
  # After user authorization, exchange code for token
  token = mcp_client.get_token_from_auth_response(
    auth_response, redirect_url, state
  )
  mcp_client.set_auth_token(token)
end

# Initialize and use the client
mcp_client.initialize_session
tools = mcp_client.get_tools
# ... use tools as shown above
```

### System Prompts

```ruby
# List available system prompts
prompts = mcp_client.list_system_prompts
puts "Available prompts: #{prompts}"

# Get a specific system prompt
prompt_result = mcp_client.get_system_prompt("code_review", {
  "language" => "ruby",
  "style" => "detailed"
})

puts "Prompt description: #{prompt_result.description}"
prompt_result.messages.each do |message|
  puts "#{message['role']}: #{message['content']['text']}"
end
```

### Error Handling

```ruby
begin
  mcp_client.initialize_session
  tools = mcp_client.get_tools
rescue MistralAI::MCP::MCPAuthException => e
  puts "Authentication error: #{e.message}"
rescue MistralAI::MCP::MCPConnectionException => e
  puts "Connection error: #{e.message}"
rescue MistralAI::MCP::MCPException => e
  puts "MCP error: #{e.message}"
end
```

### Examples

See the `examples/` directory for complete working examples:

- `examples/mcp_stdio_example.rb` - Local MCP server integration
- `examples/mcp_sse_example.rb` - Remote server with OAuth authentication
- `examples/embeddings.rb` - Embeddings API example
- `examples/fine_tuning.rb` - Fine-tuning API example


## Console Scripts

The gem includes console scripts for interactive usage:

### Interactive Chat Interface

Start an interactive chat session with streaming responses:

```bash
# Using API key parameter
./bin/mistral-chat --api-key your-api-key-here

# Using environment variable
export MISTRAL_API_KEY="your-api-key"
./bin/mistral-chat

# Specify a different model
./bin/mistral-chat --api-key your-key --model mistral-large-latest
```

**Chat Commands:**
- `help` - Show available commands
- `clear` - Clear conversation history
- `exit` or `quit` - End the conversation
- `Ctrl+C` - Exit at any time

### Development Console

For development and debugging:

```bash
./bin/console
```

This starts an IRB session with the MistralAI module pre-loaded.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mistralai/client-ruby.

## License

The gem is available as open source under the terms of the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0). 