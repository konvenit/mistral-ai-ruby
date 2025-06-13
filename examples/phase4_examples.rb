#!/usr/bin/env ruby
# frozen_string_literal: true

# Add the lib directory to the load path for development
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Load environment variables from .env file
require "dotenv"
Dotenv.load

require "mistral-ai"

# Phase 4 Advanced Features Examples
# This demonstrates tool calling and structured outputs

# Configure the client
# Make sure to set MISTRAL_API_KEY environment variable
api_key = ENV.fetch("MISTRAL_API_KEY", nil)
if api_key.nil? || api_key.empty?
  puts "⚠️  Warning: MISTRAL_API_KEY environment variable not set."
  puts "   The API examples will fail, but local validation examples will still work."
  puts "   To test API calls, set your API key: export MISTRAL_API_KEY='your-api-key'"
  puts "   Or create a .env file with: MISTRAL_API_KEY=your-api-key"
else
  puts "✓ API key loaded successfully"
end
puts

client = api_key ? MistralAI::Client.new(api_key: api_key) : nil

puts "=== Phase 4: Advanced Features Examples ==="
puts

def safe_api_call(title, client = nil)
  puts title
  puts "-" * title.length
  if client.nil?
    puts "⚠️  Skipped: No API key provided"
    puts
    return nil
  end

  begin
    result = yield
    puts "✓ Success: #{result}"
    result
  rescue StandardError => e
    puts "Error: #{e.message}"
    nil
  end
  puts
end

# ============================================================================
# TOOL CALLING EXAMPLES
# ============================================================================

puts "1. Tool Calling - Weather Function"
puts "-" * 40

# Define a weather tool using the builder pattern
weather_tool = MistralAI::Tools::FunctionTool.new(
  name: "get_weather",
  description: "Get current weather for a location",
  parameters: {
    type: "object",
    properties: {
      location: {
        type: "string",
        description: "The city name"
      },
      unit: {
        type: "string",
        enum: %w[celsius fahrenheit],
        description: "Temperature unit"
      }
    },
    required: ["location"]
  }
)

safe_api_call("1. Tool Calling - Weather Function", client) do
  response = client.chat.complete(
    model: "mistral-small-latest",
    messages: [
      { role: "user", content: "What's the weather like in Paris?" }
    ],
    tools: [weather_tool],
    tool_choice: MistralAI::Tools::ToolChoice.auto
  )

  if response.has_tool_calls?
    tool_calls = response.extract_tool_calls
    first_call = tool_calls.first
    if first_call
      "Tool called: #{first_call.function_name} with args: #{first_call.parsed_arguments}"
    else
      "Tool calls found but extraction failed - Raw data: #{response.tool_calls.first}"
    end
  else
    "No tool calls made - Response: #{response.content}"
  end
end

# ============================================================================

puts "2. Tool Calling - Multiple Tools with Complex Parameters"
puts "-" * 55

# Define multiple tools
calculator_tool = MistralAI::Tools::FunctionTool.new(
  name: "calculate",
  description: "Perform mathematical calculations",
  parameters: {
    type: "object",
    properties: {
      expression: {
        type: "string",
        description: "Mathematical expression to evaluate"
      },
      format: {
        type: "string",
        enum: %w[decimal fraction],
        description: "Output format"
      }
    },
    required: ["expression"]
  }
)

date_tool = MistralAI::Tools::FunctionTool.new(
  name: "get_date",
  description: "Get current date and time information",
  parameters: {
    type: "object",
    properties: {
      timezone: {
        type: "string",
        description: "Timezone (e.g., 'UTC', 'EST')"
      },
      format: {
        type: "string",
        enum: %w[iso human timestamp],
        description: "Date format"
      }
    },
    required: []
  }
)

safe_api_call("2. Tool Calling - Multiple Tools with Complex Parameters", client) do
  response = client.chat.complete(
    model: "mistral-small-latest",
    messages: [
      { role: "user", content: "Calculate 25 * 30 and tell me the current time in UTC" }
    ],
    tools: [calculator_tool, date_tool]
  )

  if response.has_tool_calls?
    tool_calls = response.extract_tool_calls
    "Found #{tool_calls.length} tool calls"
  else
    "No tool calls made"
  end
end

# ============================================================================

puts "3. Tool Calling - Conversation with Tool Results"
puts "-" * 48

safe_api_call("3. Tool Calling - Conversation with Tool Results", client) do
  # First, get a tool call
  response = client.chat.complete(
    model: "mistral-small-latest",
    messages: [
      { role: "user", content: "What's the weather in London?" }
    ],
    tools: [weather_tool]
  )

  if response.has_tool_calls?
    # Simulate tool execution
    tool_calls = response.extract_tool_calls
    first_call = tool_calls.first

    if first_call
      tool_result = { temperature: 18, condition: "cloudy", humidity: 75 }.to_json

      # Continue conversation with tool result
      messages = [
        { role: "user", content: "What's the weather in London?" },
        response.message.to_h,
        MistralAI::Messages::ToolMessage.new(
          tool_call_id: first_call.id,
          content: tool_result
        ).to_h
      ]

      client.chat.complete(
        model: "mistral-small-latest",
        messages: messages
      )

      "Conversation completed with tool result"
    else
      "Tool calls found but could not extract them"
    end
  else
    "No tool calls to process - Response: #{response.content}"
  end
end

# ============================================================================
# STRUCTURED OUTPUTS EXAMPLES
# ============================================================================

puts "4. Structured Outputs - Using Schema Classes"
puts "-" * 45

# Define a schema class for structured outputs
class PersonSchema < MistralAI::StructuredOutputs::BaseSchema
  title "Person Information"
  description "Schema for person data"

  string_property :name, description: "Full name", required: true
  integer_property :age, description: "Age in years", required: true, minimum: 0, maximum: 150
  string_property :email, description: "Email address"
  boolean_property :active, description: "Whether the person is active"
  array_property :hobbies, description: "List of hobbies"
end

safe_api_call("4. Structured Outputs - Using Schema Classes", client) do
  response = client.chat.complete(
    model: "mistral-small-latest",
    messages: [
      { role: "user", content: "Generate information for a person named John Doe, age 30 as JSON" }
    ],
    response_format: { type: "json_object" }
  )

  if response.content
    structured = response.structured_content(PersonSchema)
    if structured.respond_to?(:name) && structured.respond_to?(:age)
      "Generated person: #{structured.name}, age #{structured.age}"
    else
      "Generated structured response: #{structured.class} - #{structured.inspect}"
    end
  else
    "No structured content received"
  end
end

# ============================================================================

puts "5. Structured Outputs - Dynamic Schema Builder"
puts "-" * 48

# Build schema dynamically
safe_api_call("5. Structured Outputs - Dynamic Schema Builder", client) do
  MistralAI::StructuredOutputs::SchemaBuilder.new
                                             .title("Product Information")
                                             .description("Schema for product data")
                                             .string_property("name", required: true)
                                             .number_property("price", minimum: 0)
                                             .string_property("category", enum: %w[electronics clothing books])
                                             .boolean_property("in_stock")
                                             .build

  response = client.chat.complete(
    model: "mistral-small-latest",
    messages: [
      { role: "user",
        content: "Create a product for a laptop as JSON with name, price, category (electronics), and stock status" }
    ],
    response_format: { type: "json_object" }
  )

  if response.content
    response.structured_content
    "Generated product schema response"
  else
    "No structured content received"
  end
end

# ============================================================================

puts "6. Structured Outputs - Validation and Error Handling"
puts "-" * 57

# Schema with strict validation
safe_api_call("6. Structured Outputs - Validation and Error Handling", client) do
  # This will demonstrate validation
  schema = {
    type: "object",
    properties: {
      email: { type: "string", pattern: "^[^@]+@[^@]+.[^@]+$" },
      score: { type: "integer", minimum: 0, maximum: 100 }
    },
    required: %w[email score]
  }

  # Simulate a response with JSON content
  mock_data = {
    "id" => "test-123",
    "choices" => [{
      "message" => {
        "role" => "assistant",
        "content" => '{"email": "test@example.com", "score": 85}'
      },
      "index" => 0,
      "finish_reason" => "stop"
    }]
  }

  response = MistralAI::Responses::ChatResponse.new(mock_data)

  if response.validate_schema(schema)
    "Schema validation passed"
  else
    "Schema validation failed"
  end
end

# ============================================================================

puts "7. Combined Example - Tool Calling with Structured Outputs"
puts "-" * 60

# Tool that returns structured data
safe_api_call("7. Combined Example - Tool Calling with Structured Outputs", client) do
  # Define a tool that returns structured data
  analysis_tool = MistralAI::Tools::FunctionTool.new(
    name: "analyze_data",
    description: "Analyze data and return structured results",
    parameters: {
      type: "object",
      properties: {
        data: {
          type: "string",
          description: "Data to analyze"
        },
        analysis_type: {
          type: "string",
          enum: %w[statistical sentiment trend],
          description: "Type of analysis"
        }
      },
      required: ["data"]
    }
  )

  response = client.chat.complete(
    model: "mistral-small-latest",
    messages: [
      { role: "user",
        content: "Analyze the sentiment of 'I love this product' and return JSON with sentiment, confidence, and reasoning" }
    ],
    tools: [analysis_tool]
  )

  if response.has_tool_calls?
    "Tool calling with structured output configured"
  else
    "No tool calls made"
  end
end

# ============================================================================

puts "8. Error Handling and Edge Cases"
puts "-" * 35

# Test invalid function names
begin
  MistralAI::Tools::FunctionTool.new(name: "invalid-name!", description: "Test")
rescue ArgumentError => e
  puts "✓ Caught expected validation error: #{e.message}"
end

# Test schema building
schema = MistralAI::StructuredOutputs::SchemaBuilder.new
                                                    .string_property("test", enum: [])
                                                    .build

puts "Schema created: #{schema}"

# Test tool choice validation
begin
  MistralAI::Tools::ToolChoice.function("")
rescue ArgumentError => e
  puts "✓ Caught tool choice validation error: #{e.message}"
end

puts

puts "=== Phase 4 Examples Complete ==="
puts "Features demonstrated:"
puts "- Tool calling with function definitions"
puts "- Tool choice parameters (auto, none, specific)"
puts "- Structured outputs with JSON Schema"
puts "- Ruby object mapping"
puts "- Schema validation"
puts "- Error handling and validation"
puts "- Combined tool calling and structured outputs"
