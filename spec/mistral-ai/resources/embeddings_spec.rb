# frozen_string_literal: true

require "spec_helper"

RSpec.describe MistralAI::Resources::Embeddings do
  let(:client) { test_client }
  let(:embeddings) { client.embeddings }

  describe "#create" do
    context "with valid parameters" do
      let(:model) { "mistral-embed" }
      let(:input) { ["Hello, world!"] }
      let(:success_response) do
        {
          "data" => [
            {
              "embedding" => Array.new(1024) { rand(-1.0..1.0) }
            }
          ]
        }
      end

      before do
        stub_request(:post, "https://api.mistral.ai/v1/embeddings")
          .with(
            body: {
              model: model,
              input: input
            }.to_json
          )
          .to_return(
            status: 200,
            body: success_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "creates embeddings successfully" do
        response = embeddings.create(model: model, input: input)

        expect(response).to be_a(Hash)
        expect(response["data"]).to be_an(Array)
        expect(response["data"].first).to include("embedding")
        expect(response["data"].first["embedding"]).to be_an(Array)
      end

      it "handles multiple inputs" do
        multiple_inputs = ["Hello, world!", "How are you?"]
        multiple_response = {
          "data" => multiple_inputs.map do
            {
              "embedding" => Array.new(1024) { rand(-1.0..1.0) }
            }
          end
        }

        stub_request(:post, "https://api.mistral.ai/v1/embeddings")
          .with(
            body: {
              model: model,
              input: multiple_inputs
            }.to_json
          )
          .to_return(
            status: 200,
            body: multiple_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        response = embeddings.create(model: model, input: multiple_inputs)

        expect(response["data"].length).to eq(2)
        expect(response["data"].all? { |item| item["embedding"].is_a?(Array) }).to be true
      end

      it "accepts optional parameters" do
        stub_request(:post, "https://api.mistral.ai/v1/embeddings")
          .with(
            body: {
              model: model,
              input: input,
              output_dimension: 1024,
              output_dtype: "float32"
            }.to_json
          )
          .to_return(
            status: 200,
            body: success_response.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        response = embeddings.create(
          model: model,
          input: input,
          output_dimension: 1024,
          output_dtype: "float32"
        )

        expect(response).to be_a(Hash)
        expect(response["data"].first["embedding"].length).to eq(1024)
      end
    end

    context "with invalid parameters" do
      it "raises an error with invalid model" do
        stub_request(:post, "https://api.mistral.ai/v1/embeddings")
          .with(
            body: {
              model: "invalid-model",
              input: ["Hello"]
            }.to_json
          )
          .to_return(
            status: 400,
            body: { error: "Invalid model" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect do
          embeddings.create(model: "invalid-model", input: ["Hello"])
        end.to raise_error(MistralAI::BadRequestError)
      end

      it "raises an error with empty input" do
        expect do
          embeddings.create(model: "mistral-embed", input: [])
        end.to raise_error(ArgumentError, "input cannot be empty")
      end
    end
  end
end
