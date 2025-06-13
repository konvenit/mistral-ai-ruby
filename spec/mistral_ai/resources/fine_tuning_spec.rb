# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MistralAI::Resources::FineTuning do
  let(:client) { test_client }
  let(:fine_tuning) { client.fine_tuning }

  describe '#jobs' do
    it 'initializes jobs resource' do
      expect(fine_tuning.jobs).to be_a(MistralAI::Resources::Jobs)
    end

    describe 'jobs operations' do
      let(:jobs) { fine_tuning.jobs }
      let(:job_id) { 'ft-123' }
      let(:list_response) do
        {
          'data' => [
            {
              'id' => job_id,
              'model' => 'mistral-small',
              'status' => 'succeeded',
              'created_at' => Time.now.to_i
            }
          ]
        }
      end
      let(:job_response) do
        {
          'id' => job_id,
          'model' => 'mistral-small',
          'status' => 'succeeded',
          'created_at' => Time.now.to_i,
          'finished_at' => Time.now.to_i,
          'hyperparameters' => {
            'n_epochs' => 3
          }
        }
      end

      it 'lists jobs' do
        stub_request(:get, 'https://api.mistral.ai/v1/fine-tuning/jobs')
          .to_return(
            status: 200,
            body: list_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        response = jobs.list
        
        expect(response).to be_a(Hash)
        expect(response['data']).to be_an(Array)
        expect(response['data'].first['id']).to eq(job_id)
      end

      it 'creates a job' do
        training_file = 'spec/fixtures/training.jsonl'
        hyperparameters = { n_epochs: 3 }

        stub_request(:post, 'https://api.mistral.ai/v1/fine-tuning/jobs')
          .with(
            body: {
              model: 'mistral-small',
              training_file: training_file,
              hyperparameters: hyperparameters
            }.to_json
          )
          .to_return(
            status: 200,
            body: job_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        response = jobs.create(
          model: 'mistral-small',
          training_file: training_file,
          hyperparameters: hyperparameters
        )
        
        expect(response).to be_a(Hash)
        expect(response).to include('id', 'status')
        expect(response['id']).to eq(job_id)
      end

      it 'retrieves a job' do
        stub_request(:get, "https://api.mistral.ai/v1/fine-tuning/jobs/#{job_id}")
          .to_return(
            status: 200,
            body: job_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        response = jobs.retrieve(job_id: job_id)
        
        expect(response).to be_a(Hash)
        expect(response['id']).to eq(job_id)
      end

      it 'cancels a job' do
        cancelled_response = job_response.merge('status' => 'cancelled')

        stub_request(:post, "https://api.mistral.ai/v1/fine-tuning/jobs/#{job_id}/cancel")
          .to_return(
            status: 200,
            body: cancelled_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        response = jobs.cancel(job_id: job_id)
        
        expect(response).to be_a(Hash)
        expect(response['status']).to eq('cancelled')
      end
    end
  end
end 