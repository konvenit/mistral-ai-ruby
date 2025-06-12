# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MistralAI::Resources::OCR do
  let(:client) { test_client }
  let(:ocr) { client.ocr }

  describe '#process' do
    context 'with valid parameters' do
      let(:model) { 'mistral-ocr' }
      let(:document) { { url: 'https://example.com/sample.pdf' } }

      it 'processes document successfully' do
        VCR.use_cassette('ocr/process_success') do
          response = ocr.process(model: model, document: document)
          
          expect(response).to be_a(Hash)
          expect(response).to include('text', 'pages')
          expect(response['pages']).to be_an(Array)
        end
      end

      it 'handles optional parameters' do
        VCR.use_cassette('ocr/process_with_options') do
          response = ocr.process(
            model: model,
            document: document,
            pages: [0, 1],
            include_image_base64: true,
            image_limit: 5,
            image_min_size: 100
          )
          
          expect(response).to be_a(Hash)
          expect(response['pages'].length).to be <= 2
        end
      end

      it 'handles document with base64 content' do
        VCR.use_cassette('ocr/process_base64') do
          base64_content = Base64.strict_encode64(File.read('spec/fixtures/sample.pdf'))
          response = ocr.process(
            model: model,
            document: { content: base64_content }
          )
          
          expect(response).to be_a(Hash)
          expect(response).to include('text', 'pages')
        end
      end
    end

    context 'with invalid parameters' do
      it 'raises an error with invalid model' do
        VCR.use_cassette('ocr/process_invalid_model') do
          expect {
            ocr.process(model: 'invalid-model', document: { url: 'https://example.com/doc.pdf' })
          }.to raise_error(MistralAI::APIError)
        end
      end

      it 'raises an error with invalid document' do
        expect {
          ocr.process(model: 'mistral-ocr', document: {})
        }.to raise_error(MistralAI::ValidationError)
      end
    end
  end

  describe '#process_async' do
    let(:model) { 'mistral-ocr' }
    let(:document) { { url: 'https://example.com/sample.pdf' } }

    it 'processes document asynchronously' do
      VCR.use_cassette('ocr/process_async_success') do
        response = ocr.process_async(model: model, document: document)
        
        expect(response).to be_a(Hash)
        expect(response).to include('text', 'pages')
      end
    end
  end
end 