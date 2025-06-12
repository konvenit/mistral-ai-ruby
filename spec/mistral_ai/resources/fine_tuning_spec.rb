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

      it 'lists jobs' do
        VCR.use_cassette('fine_tuning/jobs/list') do
          response = jobs.list
          
          expect(response).to be_a(Hash)
          expect(response['data']).to be_an(Array)
        end
      end

      it 'creates a job' do
        VCR.use_cassette('fine_tuning/jobs/create') do
          training_file = 'spec/fixtures/training.jsonl'
          response = jobs.create(
            model: 'mistral-small',
            training_file: training_file,
            hyperparameters: {
              n_epochs: 3
            }
          )
          
          expect(response).to be_a(Hash)
          expect(response).to include('id', 'status')
        end
      end

      it 'retrieves a job' do
        VCR.use_cassette('fine_tuning/jobs/retrieve') do
          job_id = 'ft-123' # Replace with actual job ID from VCR
          response = jobs.retrieve(job_id: job_id)
          
          expect(response).to be_a(Hash)
          expect(response['id']).to eq(job_id)
        end
      end

      it 'cancels a job' do
        VCR.use_cassette('fine_tuning/jobs/cancel') do
          job_id = 'ft-123' # Replace with actual job ID from VCR
          response = jobs.cancel(job_id: job_id)
          
          expect(response).to be_a(Hash)
          expect(response['status']).to eq('cancelled')
        end
      end
    end
  end
end 