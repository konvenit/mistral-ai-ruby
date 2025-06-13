# frozen_string_literal: true

require "spec_helper"

RSpec.describe MistralAI::StructuredOutputs do
  describe MistralAI::StructuredOutputs::BaseSchema do
    let(:test_schema_class) do
      Class.new(described_class) do
        title "Test Schema"
        description "A test schema"

        string_property :name, description: "Name", required: true
        integer_property :age, description: "Age", minimum: 0, maximum: 150
        boolean_property :active, description: "Active status"
        array_property :tags, description: "Tags", items: { type: "string" }
      end
    end

    describe "class methods" do
      it "generates correct JSON schema" do
        schema = test_schema_class.to_json_schema

        expect(schema[:type]).to eq("object")
        expect(schema[:title]).to eq("Test Schema")
        expect(schema[:description]).to eq("A test schema")
        expect(schema[:additionalProperties]).to be false
        expect(schema[:required]).to include(:name)

        properties = schema[:properties]
        expect(properties[:name][:type]).to eq("string")
        expect(properties[:age][:type]).to eq("integer")
        expect(properties[:age][:minimum]).to eq(0)
        expect(properties[:age][:maximum]).to eq(150)
        expect(properties[:active][:type]).to eq("boolean")
        expect(properties[:tags][:type]).to eq("array")
        expect(properties[:tags][:items]).to eq({ type: "string" })
      end

      it "generates response format" do
        format = test_schema_class.response_format

        expect(format[:type]).to eq("json_object")
        expect(format[:schema]).to be_a(Hash)
        expect(format[:schema][:type]).to eq("object")
      end

      it "creates instance from JSON" do
        json_data = '{"name": "John", "age": 30, "active": true, "tags": ["user", "admin"]}'
        instance = test_schema_class.from_json(json_data)

        expect(instance.name).to eq("John")
        expect(instance.age).to eq(30)
        expect(instance.active).to be true
        expect(instance.tags).to eq(%w[user admin])
      end

      it "creates instance from hash" do
        hash_data = {
          "name" => "Jane",
          "age" => 25,
          "active" => false,
          "tags" => ["user"]
        }
        instance = test_schema_class.from_hash(hash_data)

        expect(instance.name).to eq("Jane")
        expect(instance.age).to eq(25)
        expect(instance.active).to be false
        expect(instance.tags).to eq(["user"])
      end
    end

    describe "instance methods" do
      let(:instance) { test_schema_class.new }

      before do
        instance.instance_variable_set(:@name, "Test")
        instance.instance_variable_set(:@age, 25)
        instance.instance_variable_set(:@active, true)
        instance.define_singleton_method(:name) { @name }
        instance.define_singleton_method(:age) { @age }
        instance.define_singleton_method(:active) { @active }
      end

      it "validates required fields" do
        expect { instance.validate! }.not_to raise_error

        instance.instance_variable_set(:@name, nil)
        expect { instance.validate! }.to raise_error(MistralAI::StructuredOutputs::ValidationError)
      end

      it "converts to hash" do
        hash = instance.to_h
        expect(hash[:name]).to eq("Test")
        expect(hash[:age]).to eq(25)
        expect(hash[:active]).to be true
      end

      it "converts to JSON" do
        json = instance.to_json
        parsed = JSON.parse(json)
        expect(parsed["name"]).to eq("Test")
        expect(parsed["age"]).to eq(25)
        expect(parsed["active"]).to be true
      end

      it "checks validity" do
        expect(instance.valid?).to be true

        instance.instance_variable_set(:@name, nil)
        expect(instance.valid?).to be false
      end
    end
  end

  describe MistralAI::StructuredOutputs::SchemaBuilder do
    describe "#build" do
      it "builds a basic schema" do
        schema = described_class.new
                                .title("User Schema")
                                .description("Schema for user data")
                                .string_property(:username, description: "Username", required: true)
                                .integer_property(:score, description: "User score", minimum: 0)
                                .build

        expect(schema[:type]).to eq("object")
        expect(schema[:title]).to eq("User Schema")
        expect(schema[:description]).to eq("Schema for user data")
        expect(schema[:additionalProperties]).to be false
        expect(schema[:required]).to include(:username)

        properties = schema[:properties]
        expect(properties[:username][:type]).to eq("string")
        expect(properties[:score][:type]).to eq("integer")
        expect(properties[:score][:minimum]).to eq(0)
      end

      it "builds schema with enum properties" do
        schema = described_class.new
                                .string_property(:status, enum: %w[active inactive], required: true)
                                .build

        expect(schema[:properties][:status][:enum]).to eq(%w[active inactive])
      end

      it "builds schema with array properties" do
        schema = described_class.new
                                .array_property(:items, items: { type: "string" }, required: true)
                                .build

        expect(schema[:properties][:items][:type]).to eq("array")
        expect(schema[:properties][:items][:items]).to eq({ type: "string" })
      end

      it "builds schema with object properties" do
        schema = described_class.new
                                .object_property(:address, properties: {
                                                   street: { type: "string" },
                                                   city: { type: "string" }
                                                 })
                                .build

        expect(schema[:properties][:address][:type]).to eq("object")
        expect(schema[:properties][:address][:properties][:street][:type]).to eq("string")
      end

      it "sets additional properties" do
        schema = described_class.new
                                .additional_properties(true)
                                .build

        expect(schema[:additionalProperties]).to be true
      end
    end

    describe "#response_format" do
      it "returns response format" do
        builder = described_class.new.string_property(:name, required: true)
        format = builder.response_format

        expect(format[:type]).to eq("json_object")
        expect(format[:schema][:type]).to eq("object")
        expect(format[:schema][:properties][:name][:type]).to eq("string")
      end
    end
  end

  describe MistralAI::StructuredOutputs::ObjectMapper do
    describe ".map" do
      it "maps JSON string to structured object" do
        json_str = '{"name": "John", "age": 30, "active": true}'
        result = described_class.map(json_str)

        expect(result).to be_a(MistralAI::StructuredOutputs::StructuredObject)
        expect(result.name).to eq("John")
        expect(result.age).to eq(30)
        expect(result.active).to be true
      end

      it "maps hash to structured object" do
        hash = { "name" => "Jane", "age" => 25 }
        result = described_class.map(hash)

        expect(result).to be_a(MistralAI::StructuredOutputs::StructuredObject)
        expect(result.name).to eq("Jane")
        expect(result.age).to eq(25)
      end

      it "maps array of objects" do
        array = [
          { "name" => "John", "age" => 30 },
          { "name" => "Jane", "age" => 25 }
        ]
        result = described_class.map(array)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result.first.name).to eq("John")
        expect(result.last.name).to eq("Jane")
      end

      it "maps with schema class" do
        schema_class = Class.new(MistralAI::StructuredOutputs::BaseSchema) do
          string_property :name, required: true
          integer_property :age, required: true
        end

        allow(schema_class).to receive(:from_hash).and_return("mapped_object")

        hash = { "name" => "John", "age" => 30 }
        result = described_class.map(hash, schema_class)

        expect(schema_class).to have_received(:from_hash).with(hash)
        expect(result).to eq("mapped_object")
      end

      it "raises error for invalid JSON" do
        expect do
          described_class.map("invalid json")
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Invalid JSON/)
      end
    end
  end

  describe MistralAI::StructuredOutputs::StructuredObject do
    let(:data) { { "name" => "John", "age" => 30, "active" => true } }
    let(:object) { described_class.new(data) }

    describe "#initialize" do
      it "creates accessors for data keys" do
        expect(object.name).to eq("John")
        expect(object.age).to eq(30)
        expect(object.active).to be true
      end

      it "creates question methods for boolean values" do
        expect(object.active?).to be true
      end

      it "handles nested objects" do
        nested_data = {
          "user" => { "name" => "John", "age" => 30 },
          "settings" => { "theme" => "dark" }
        }
        nested_object = described_class.new(nested_data)

        expect(nested_object.user).to be_a(described_class)
        expect(nested_object.user.name).to eq("John")
        expect(nested_object.settings.theme).to eq("dark")
      end

      it "handles arrays with nested objects" do
        array_data = {
          "users" => [
            { "name" => "John" },
            { "name" => "Jane" }
          ]
        }
        array_object = described_class.new(array_data)

        expect(array_object.users).to be_an(Array)
        expect(array_object.users.first).to be_a(described_class)
        expect(array_object.users.first.name).to eq("John")
      end
    end

    describe "#[]" do
      it "accesses values by string key" do
        expect(object["name"]).to eq("John")
        expect(object["age"]).to eq(30)
      end

      it "accesses values by symbol key" do
        expect(object[:name]).to eq("John")
        expect(object[:age]).to eq(30)
      end
    end

    describe "#[]=" do
      it "sets values and creates accessor" do
        object["email"] = "john@example.com"
        expect(object["email"]).to eq("john@example.com")
        expect(object.email).to eq("john@example.com")
      end
    end

    describe "#key?" do
      it "checks for key existence" do
        expect(object.key?("name")).to be true
        expect(object.key?(:name)).to be true
        expect(object.key?("missing")).to be false
      end
    end

    describe "#keys" do
      it "returns data keys" do
        expect(object.keys).to include("name", "age", "active")
      end
    end

    describe "#values" do
      it "returns data values" do
        expect(object.values).to include("John", 30, true)
      end
    end

    describe "#each" do
      it "iterates over key-value pairs" do
        result = {}
        object.each { |k, v| result[k] = v }
        expect(result).to eq(data)
      end
    end

    describe "#to_h" do
      it "returns original data" do
        expect(object.to_h).to eq(data)
      end
    end

    describe "#to_json" do
      it "converts to JSON" do
        json = object.to_json
        parsed = JSON.parse(json)
        expect(parsed).to eq(data)
      end
    end

    describe "method_missing" do
      it "handles dynamic attribute access" do
        expect(object.name).to eq("John")
        expect(object.active?).to be true
      end

      it "raises error for unknown attributes" do
        expect { object.unknown_attribute }.to raise_error(NoMethodError)
      end
    end
  end

  describe MistralAI::StructuredOutputs::Utils do
    describe ".validate_json" do
      let(:schema) do
        {
          type: "object",
          properties: {
            name: { type: "string" },
            age: { type: "integer", minimum: 0 }
          },
          required: ["name"]
        }
      end

      it "validates valid JSON against schema" do
        json = '{"name": "John", "age": 30}'
        expect { described_class.validate_json(json, schema) }.not_to raise_error
      end

      it "raises error for invalid JSON" do
        expect do
          described_class.validate_json("invalid json", schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Invalid JSON/)
      end

      it "raises error for missing required fields" do
        json = '{"age": 30}'
        expect do
          described_class.validate_json(json, schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Required field 'name' is missing/)
      end
    end

    describe ".validate_data" do
      let(:schema) do
        {
          type: "object",
          properties: {
            name: { type: "string" },
            age: { type: "integer", minimum: 18, maximum: 100 },
            email: { type: "string", pattern: "^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}$" },
            status: { type: "string", enum: %w[active inactive] },
            score: { type: "number", minimum: 0.0, maximum: 100.0 },
            verified: { type: "boolean" },
            tags: { type: "array" },
            meta: { type: "object" }
          },
          required: %w[name age]
        }
      end

      it "validates correct data" do
        data = {
          "name" => "John",
          "age" => 30,
          "email" => "john@example.com",
          "status" => "active",
          "score" => 85.5,
          "verified" => true,
          "tags" => ["user"],
          "meta" => {}
        }

        expect { described_class.validate_data(data, schema) }.not_to raise_error
      end

      it "validates required fields" do
        data = { "age" => 30 }
        expect do
          described_class.validate_data(data, schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Required field 'name' is missing/)
      end

      it "validates string type" do
        data = { "name" => 123, "age" => 30 }
        expect do
          described_class.validate_data(data, schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Property 'name' must be a string/)
      end

      it "validates integer type" do
        data = { "name" => "John", "age" => "thirty" }
        expect do
          described_class.validate_data(data, schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Property 'age' must be an integer/)
      end

      it "validates number type" do
        data = { "name" => "John", "age" => 30, "score" => "invalid" }
        expect do
          described_class.validate_data(data, schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Property 'score' must be a number/)
      end

      it "validates boolean type" do
        data = { "name" => "John", "age" => 30, "verified" => "yes" }
        expect do
          described_class.validate_data(data, schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Property 'verified' must be a boolean/)
      end

      it "validates array type" do
        data = { "name" => "John", "age" => 30, "tags" => "tag1,tag2" }
        expect do
          described_class.validate_data(data, schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Property 'tags' must be an array/)
      end

      it "validates object type" do
        data = { "name" => "John", "age" => 30, "meta" => "string" }
        expect do
          described_class.validate_data(data, schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Property 'meta' must be an object/)
      end

      it "validates minimum constraints" do
        data = { "name" => "John", "age" => 15 }
        expect do
          described_class.validate_data(data, schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Property 'age' must be >= 18/)
      end

      it "validates maximum constraints" do
        data = { "name" => "John", "age" => 150 }
        expect do
          described_class.validate_data(data, schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Property 'age' must be <= 100/)
      end

      it "validates enum constraints" do
        data = { "name" => "John", "age" => 30, "status" => "unknown" }
        expect do
          described_class.validate_data(data, schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Property 'status' must be one of: active, inactive/)
      end

      it "validates pattern constraints" do
        data = { "name" => "John", "age" => 30, "email" => "invalid-email" }
        expect do
          described_class.validate_data(data, schema)
        end.to raise_error(MistralAI::StructuredOutputs::ValidationError, /Property 'email' does not match pattern/)
      end
    end

    describe ".response_format" do
      it "creates response format from schema" do
        schema = { type: "object", properties: { name: { type: "string" } } }
        format = described_class.response_format(schema)

        expect(format[:type]).to eq("json_object")
        expect(format[:schema]).to eq(schema)
      end
    end
  end
end
