# Mistral AI Ruby Client

A Ruby client library for accessing the Mistral AI API, including chat completions, agents, and streaming support.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mistral_ai'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install mistral_ai

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
require 'mistral_ai'

# Configure globally
MistralAI.configure do |config|
  config.api_key = "your-api-key"
end

# Use the global client
client = MistralAI.client

# Chat completion (Phase 2 - Coming Soon)
# response = client.chat.complete(
#   model: "mistral-small-latest",
#   messages: [
#     { role: "user", content: "What is the best French cheese?" }
#   ]
# )
```

### Client Instance

```ruby
require 'mistral_ai'

client = MistralAI::Client.new(api_key: "your-api-key")

# Chat completion (Phase 2 - Coming Soon)
# response = client.chat.complete(
#   model: "mistral-small-latest", 
#   messages: [
#     { role: "user", content: "Hello!" }
#   ]
# )
```

## Development Status

This Ruby client is currently in development following a phased approach:

### ✅ Phase 1: Foundation & Core Infrastructure (Current)
- [x] Project setup and gem structure
- [x] Configuration management
- [x] HTTP client with Faraday
- [x] Error handling and custom exceptions
- [x] Authentication
- [x] Basic testing infrastructure

### 🚧 Phase 2: Chat API Implementation (Coming Soon)
- [ ] Synchronous chat completion
- [ ] Message types and validation  
- [ ] Response objects
- [ ] Streaming support

### 🚧 Phase 3: Agents API Implementation (Planned)
- [ ] Agent completions
- [ ] Agent streaming

### 🚧 Phase 4: Advanced Features (Planned)
- [ ] Tool calling support
- [ ] Structured outputs

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mistralai/client-ruby.

## License

The gem is available as open source under the terms of the [Apache 2.0 License](https://opensource.org/licenses/Apache-2.0). 