#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/mistral-ai'
require 'base64'
require 'dotenv'

# Load environment variables from .env file
Dotenv.load

# Check for API key
unless ENV['MISTRAL_API_KEY']
  puts "Error: MISTRAL_API_KEY not found in environment variables"
  puts "Please set MISTRAL_API_KEY in your .env file"
  exit 1
end

begin
  # Initialize the client
  client = MistralAI::Client.new(api_key: ENV['MISTRAL_API_KEY'])

  # Create a sample PDF file for testing
  sample_pdf_path = 'sample.pdf'
  unless File.exist?(sample_pdf_path)
    puts "Creating a sample PDF file..."
    require 'prawn'
    Prawn::Document.generate(sample_pdf_path) do
      text "This is a sample PDF file for OCR testing."
      text "It contains multiple lines of text."
      text "And some more text to process."
    end
  end

  # Process a document from file
  puts "\nProcessing local PDF file..."
  file_content = File.read(sample_pdf_path)
  base64_content = Base64.strict_encode64(file_content)

  response = client.ocr.process(
    model: 'mistral-ocr',
    document: { content: base64_content }
  )

  puts "Document from file:"
  puts "Number of pages: #{response['pages'].length}"
  puts "First page text preview: #{response['text'][0..100]}..."

  # Process with custom options
  puts "\nProcessing with custom options..."
  response = client.ocr.process(
    model: 'mistral-ocr',
    document: { content: base64_content },
    pages: [0],  # Process only first page
    include_image_base64: true,
    image_limit: 5,
    image_min_size: 100
  )

  puts "Document with custom options:"
  puts "Number of pages processed: #{response['pages'].length}"
  puts "Number of images extracted: #{response['images'].length}" if response['images']

  # Process with custom annotation format
  puts "\nProcessing with custom annotation format..."
  response = client.ocr.process(
    model: 'mistral-ocr',
    document: { content: base64_content },
    bbox_annotation_format: {
      type: 'json_schema',
      schema: {
        type: 'object',
        properties: {
          text: { type: 'string' },
          confidence: { type: 'number' }
        }
      }
    }
  )

  puts "Document with custom annotation:"
  puts "Number of annotated boxes: #{response['annotations'].length}" if response['annotations']

rescue MistralAI::APIError => e
  puts "API Error: #{e.message}"
  puts "Status code: #{e.status_code}"
  puts "Response body: #{e.response_body}"
rescue StandardError => e
  puts "Error: #{e.message}"
  puts e.backtrace
ensure
  # Clean up sample PDF file
  File.delete(sample_pdf_path) if File.exist?(sample_pdf_path)
end 