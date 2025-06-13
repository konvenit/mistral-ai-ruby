# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MistralAI::Resources::OCR do
  let(:client) { test_client }
  let(:ocr) { client.ocr }

  describe '#process' do
    context 'with valid parameters' do
      let(:model) { 'mistral-ocr' }
      let(:document) { { url: 'https://example.com/sample.pdf' } }
      let(:success_response) do
        {
          'text' => 'Sample text from document',
          'pages' => [
            {
              'page_number' => 1,
              'text' => 'Page 1 content',
              'images' => []
            }
          ]
        }
      end

      before do
        stub_request(:post, 'https://api.mistral.ai/v1/ocr')
          .with(
            body: {
              model: model,
              document: document
            }.to_json
          )
          .to_return(
            status: 200,
            body: success_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'processes document successfully' do
        response = ocr.process(model: model, document: document)
        
        expect(response).to be_a(Hash)
        expect(response).to include('text', 'pages')
        expect(response['pages']).to be_an(Array)
      end

      it 'handles optional parameters' do
        options = {
          pages: [0, 1],
          include_image_base64: true,
          image_limit: 5,
          image_min_size: 100
        }

        stub_request(:post, 'https://api.mistral.ai/v1/ocr')
          .with(
            body: {
              model: model,
              document: document,
              **options
            }.to_json
          )
          .to_return(
            status: 200,
            body: success_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        response = ocr.process(
          model: model,
          document: document,
          **options
        )
        
        expect(response).to be_a(Hash)
        expect(response['pages'].length).to be <= 2
      end

      xit 'handles document with base64 content' do
        base64_content = Base64.strict_encode64(File.read('spec/fixtures/sample.pdf'))
        base64_document = { content: base64_content }

        stub_request(:post, 'https://api.mistral.ai/v1/ocr')
          .with(
            body: {
              model: model,
              document: base64_document
            }.to_json
          )
          .to_return(
            status: 200,
            body: success_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        response = ocr.process(
          model: model,
          document: base64_document
        )
        
        expect(response).to be_a(Hash)
        expect(response).to include('text', 'pages')
      end
    end

    context 'with invalid parameters' do
      it 'raises an error with invalid model' do
        stub_request(:post, 'https://api.mistral.ai/v1/ocr')
          .with(
            body: {
              model: 'invalid-model',
              document: { url: 'https://example.com/doc.pdf' }
            }.to_json
          )
          .to_return(
            status: 400,
            body: { error: 'Invalid model' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        expect {
          ocr.process(model: 'invalid-model', document: { url: 'https://example.com/doc.pdf' })
        }.to raise_error(MistralAI::BadRequestError)
      end

      xit 'raises an error with invalid document' do
        expect {
          ocr.process(model: 'mistral-ocr', document: {})
        }.to raise_error(MistralAI::ValidationError)
      end
    end
  end

  describe '#process_async' do
    let(:model) { 'mistral-ocr' }
    let(:document) { { url: 'https://example.com/sample.pdf' } }
    let(:success_response) do
      {
        'text' => 'Sample text from document',
        'pages' => [
          {
            'page_number' => 1,
            'text' => 'Page 1 content',
            'images' => []
          }
        ]
      }
    end

    xit 'processes document asynchronously' do
      stub_request(:post, 'https://api.mistral.ai/v1/ocr/async')
        .with(
          body: {
            model: model,
            document: document
          }.to_json
        )
        .to_return(
          status: 200,
          body: success_response.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      response = ocr.process_async(model: model, document: document)
      
      expect(response).to be_a(Hash)
      expect(response).to include('text', 'pages')
    end
  end
end 