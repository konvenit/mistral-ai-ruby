#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/mistral_ai'

# Initialize the client
client = MistralAI::Client.new(api_key: ENV['MISTRAL_API_KEY'])

# List all fine-tuning jobs
jobs = client.fine_tuning.jobs.list
puts "Current jobs:"
jobs['data'].each do |job|
  puts "- #{job['id']}: #{job['status']}"
end

# Create a new fine-tuning job
training_file = 'path/to/your/training.jsonl'
response = client.fine_tuning.jobs.create(
  model: 'mistral-small',
  training_file: training_file,
  hyperparameters: {
    n_epochs: 3,
    batch_size: 4,
    learning_rate: 2e-5
  }
)

puts "\nCreated new job:"
puts "Job ID: #{response['id']}"
puts "Status: #{response['status']}"

# Retrieve job details
job_id = response['id']
job_details = client.fine_tuning.jobs.retrieve(job_id)

puts "\nJob details:"
puts "Model: #{job_details['model']}"
puts "Status: #{job_details['status']}"
puts "Created at: #{job_details['created_at']}"
puts "Finished at: #{job_details['finished_at']}" if job_details['finished_at']

# Cancel a job if needed
if job_details['status'] == 'running'
  cancelled_job = client.fine_tuning.jobs.cancel(job_id)
  puts "\nCancelled job:"
  puts "Status: #{cancelled_job['status']}"
end 