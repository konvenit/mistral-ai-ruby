#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/mistral-ai"
require "dotenv"

# Load environment variables from .env file
Dotenv.load

# Check for API key
unless ENV["MISTRAL_API_KEY"]
  puts "Error: MISTRAL_API_KEY not found in environment variables"
  puts "Please set MISTRAL_API_KEY in your .env file"
  exit 1
end

begin
  # Initialize the client
  client = MistralAI::Client.new(api_key: ENV.fetch("MISTRAL_API_KEY", nil))

  # Create embeddings for a single text
  puts "\nCreating embedding for single text..."
  response = client.embeddings.create(
    model: "mistral-embed",
    input: "Hello, world!"
  )

  puts "Single text embedding:"
  puts "Embedding dimension: #{response['data'][0]['embedding'].length}"
  puts "First few values: #{response['data'][0]['embedding'][0..5]}"

  # Create embeddings for multiple texts
  puts "\nCreating embeddings for multiple texts..."
  multiple_texts = [
    "Hello, world!",
    "How are you?",
    "What is the weather like?"
  ]

  response = client.embeddings.create(
    model: "mistral-embed",
    input: multiple_texts
  )

  puts "\nMultiple text embeddings:"
  puts "Number of embeddings: #{response['data'].length}"
  response["data"].each_with_index do |item, index|
    puts "Text #{index + 1} embedding dimension: #{item['embedding'].length}"
  end
rescue MistralAI::APIError => e
  puts "API Error: #{e.message}"
  puts "Status code: #{e.status_code}"
  puts "Response body: #{e.response_body}"
rescue StandardError => e
  puts "Error: #{e.message}"
  puts e.backtrace
end
