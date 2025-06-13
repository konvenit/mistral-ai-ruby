# frozen_string_literal: true

require "json"

module MistralAI
  module StructuredOutputs
    # Base class for structured output schemas
    class BaseSchema
      def self.inherited(subclass)
        subclass.instance_variable_set(:@properties, {})
        subclass.instance_variable_set(:@required_fields, [])
        subclass.instance_variable_set(:@title, subclass.name)
        subclass.instance_variable_set(:@description, nil)
      end

      def self.title(title_text)
        @title = title_text
      end

      def self.description(description_text)
        @description = description_text
      end

      def self.property(name, type:, description: nil, required: false, **options)
        @properties ||= {}
        @required_fields ||= []

        @properties[name] = {
          type: type,
          description: description
        }.merge(options).compact

        @required_fields << name if required
      end

      def self.string_property(name, description: nil, required: false, enum: nil, pattern: nil)
        options = {}
        options[:enum] = enum if enum
        options[:pattern] = pattern if pattern
        property(name, type: "string", description: description, required: required, **options)
      end

      def self.number_property(name, description: nil, required: false, minimum: nil, maximum: nil)
        options = {}
        options[:minimum] = minimum if minimum
        options[:maximum] = maximum if maximum
        property(name, type: "number", description: description, required: required, **options)
      end

      def self.integer_property(name, description: nil, required: false, minimum: nil, maximum: nil)
        options = {}
        options[:minimum] = minimum if minimum
        options[:maximum] = maximum if maximum
        property(name, type: "integer", description: description, required: required, **options)
      end

      def self.boolean_property(name, description: nil, required: false)
        property(name, type: "boolean", description: description, required: required)
      end

      def self.array_property(name, description: nil, required: false, items: nil)
        options = {}
        options[:items] = items if items
        property(name, type: "array", description: description, required: required, **options)
      end

      def self.object_property(name, description: nil, required: false, properties: nil)
        options = {}
        options[:properties] = properties if properties
        property(name, type: "object", description: description, required: required, **options)
      end

      def self.to_json_schema
        schema = {
          type: "object",
          properties: @properties || {},
          required: @required_fields || []
        }

        schema[:title] = @title if @title
        schema[:description] = @description if @description
        schema[:additionalProperties] = false

        schema
      end

      def self.response_format
        {
          type: "json_object",
          schema: to_json_schema
        }
      end

      def self.from_json(json_str)
        data = JSON.parse(json_str)
        from_hash(data)
      end

      def self.from_hash(data)
        # If data is an array, use the first element (common with API responses)
        if data.is_a?(Array)
          raise ValidationError, "Cannot create schema from empty array" if data.empty?

          data = data.first
        end

        # Ensure we have a hash to work with
        raise ValidationError, "Expected Hash or Array, got #{data.class}" unless data.is_a?(Hash)

        instance = new

        (@properties || {}).each_key do |name|
          # Check for key existence rather than truthiness to handle false values
          value = if data.key?(name.to_s)
                    data[name.to_s]
                  elsif data.key?(name.to_sym)
                    data[name.to_sym]
                  end

          instance.instance_variable_set("@#{name}", value)

          # Define getter method
          instance.define_singleton_method(name) { value }
        end

        instance.validate!
        instance
      end

      def initialize
        @errors = []
      end

      def validate!
        @errors = []

        (self.class.instance_variable_get(:@required_fields) || []).each do |field|
          value = instance_variable_get("@#{field}")
          @errors << "Required field '#{field}' is missing" if value.nil?
        end

        raise ValidationError, @errors.join(", ") unless @errors.empty?
      end

      def to_h
        hash = {}
        (self.class.instance_variable_get(:@properties) || {}).each_key do |name|
          value = instance_variable_get("@#{name}")
          hash[name] = value unless value.nil?
        end
        hash
      end

      def to_json(*args)
        to_h.to_json(*args)
      end

      def valid?
        validate!
        true
      rescue ValidationError
        false
      end

      def errors
        @errors ||= []
      end
    end

    # Exception for schema validation errors
    class ValidationError < StandardError; end

    # JSON Schema builder for creating schemas programmatically
    class SchemaBuilder
      def initialize
        @schema = {
          type: "object",
          properties: {},
          required: []
        }
      end

      def title(title_text)
        @schema[:title] = title_text
        self
      end

      def description(description_text)
        @schema[:description] = description_text
        self
      end

      def property(name, type:, description: nil, required: false, **options)
        @schema[:properties][name] = {
          type: type,
          description: description
        }.merge(options).compact

        @schema[:required] << name if required
        self
      end

      def string_property(name, description: nil, required: false, enum: nil, pattern: nil)
        options = {}
        options[:enum] = enum if enum
        options[:pattern] = pattern if pattern
        property(name, type: "string", description: description, required: required, **options)
      end

      def number_property(name, description: nil, required: false, minimum: nil, maximum: nil)
        options = {}
        options[:minimum] = minimum if minimum
        options[:maximum] = maximum if maximum
        property(name, type: "number", description: description, required: required, **options)
      end

      def integer_property(name, description: nil, required: false, minimum: nil, maximum: nil)
        options = {}
        options[:minimum] = minimum if minimum
        options[:maximum] = maximum if maximum
        property(name, type: "integer", description: description, required: required, **options)
      end

      def boolean_property(name, description: nil, required: false)
        property(name, type: "boolean", description: description, required: required)
      end

      def array_property(name, description: nil, required: false, items: nil)
        options = {}
        options[:items] = items if items
        property(name, type: "array", description: description, required: required, **options)
      end

      def object_property(name, description: nil, required: false, properties: nil)
        options = {}
        options[:properties] = properties if properties
        property(name, type: "object", description: description, required: required, **options)
      end

      def additional_properties(allowed = false)
        @schema[:additionalProperties] = allowed
        self
      end

      def build
        @schema[:additionalProperties] = false unless @schema.key?(:additionalProperties)
        @schema
      end

      def response_format
        {
          type: "json_object",
          schema: build
        }
      end
    end

    # Object mapper for converting JSON responses to Ruby objects
    class ObjectMapper
      def self.map(json_data, schema_class = nil)
        case json_data
        when String
          parsed = JSON.parse(json_data)
          map_object(parsed, schema_class)
        when Hash
          map_object(json_data, schema_class)
        when Array
          # If it's an array and we have a schema class, try to use the first object
          if schema_class && !json_data.empty?
            map_object(json_data.first, schema_class)
          else
            json_data.map { |item| map(item, schema_class) }
          end
        else
          json_data
        end
      rescue JSON::ParserError => e
        raise ValidationError, "Invalid JSON: #{e.message}"
      end

      def self.map_object(data, schema_class)
        if schema_class.respond_to?(:from_hash)
          schema_class.from_hash(data)
        else
          StructuredObject.new(data)
        end
      end
    end

    # Generic structured object for dynamic JSON responses
    class StructuredObject
      def initialize(data)
        @data = data.is_a?(Hash) ? data : {}

        @data.each do |key, value|
          # Convert nested hashes to structured objects
          processed_value = case value
                            when Hash
                              StructuredObject.new(value)
                            when Array
                              value.map { |item| item.is_a?(Hash) ? StructuredObject.new(item) : item }
                            else
                              value
                            end

          instance_variable_set("@#{key}", processed_value)

          # Define getter method
          define_singleton_method(key) { processed_value }

          # Define question method for boolean-like access
          define_singleton_method("#{key}?") { !!processed_value } if [true, false].include?(processed_value)
        end
      end

      def to_h
        @data
      end

      def to_json(*args)
        @data.to_json(*args)
      end

      def [](key)
        @data[key.to_s] || @data[key.to_sym]
      end

      def []=(key, value)
        @data[key] = value
        instance_variable_set("@#{key}", value)
        define_singleton_method(key) { value }
      end

      def key?(key)
        @data.key?(key.to_s) || @data.key?(key.to_sym)
      end

      def keys
        @data.keys
      end

      def values
        @data.values
      end

      def each(&block)
        @data.each(&block)
      end

      def inspect
        "#<#{self.class.name}:#{object_id} #{@data.inspect}>"
      end

      def respond_to_missing?(method_name, include_private = false)
        key = method_name.to_s.chomp("?")
        @data.key?(key) || @data.key?(key.to_sym) || super
      end

      def method_missing(method_name, *args)
        key = method_name.to_s.chomp("?")

        if @data.key?(key) || @data.key?(key.to_sym)
          value = @data[key] || @data[key.to_sym]
          method_name.to_s.end_with?("?") ? !value.nil? : value
        else
          super
        end
      end
    end

    # Utility methods for structured outputs
    module Utils
      # Validate JSON against a schema
      def self.validate_json(json_str, schema)
        data = JSON.parse(json_str)
        validate_data(data, schema)
        true
      rescue JSON::ParserError => e
        raise ValidationError, "Invalid JSON: #{e.message}"
      end

      # Validate data against a schema
      def self.validate_data(data, schema)
        errors = []

        schema[:required]&.each do |field|
          errors << "Required field '#{field}' is missing" unless data.key?(field.to_s) || data.key?(field.to_sym)
        end

        if schema[:properties]
          data.each do |key, value|
            property_schema = schema[:properties][key.to_sym] || schema[:properties][key.to_s]
            next unless property_schema

            validate_property(key, value, property_schema, errors)
          end
        end

        raise ValidationError, errors.join(", ") unless errors.empty?
      end

      # Validate a single property
      def self.validate_property(key, value, property_schema, errors)
        type = property_schema[:type]

        case type
        when "string"
          errors << "Property '#{key}' must be a string" unless value.is_a?(String)

          if property_schema[:enum] && !property_schema[:enum].include?(value)
            errors << "Property '#{key}' must be one of: #{property_schema[:enum].join(', ')}"
          end

          if property_schema[:pattern] && value !~ Regexp.new(property_schema[:pattern])
            errors << "Property '#{key}' does not match pattern #{property_schema[:pattern]}"
          end

        when "number"
          unless value.is_a?(Numeric)
            errors << "Property '#{key}' must be a number"
            return # Skip constraint checks if type is wrong
          end

          if property_schema[:minimum] && value < property_schema[:minimum]
            errors << "Property '#{key}' must be >= #{property_schema[:minimum]}"
          end

          if property_schema[:maximum] && value > property_schema[:maximum]
            errors << "Property '#{key}' must be <= #{property_schema[:maximum]}"
          end

        when "integer"
          unless value.is_a?(Integer)
            errors << "Property '#{key}' must be an integer"
            return # Skip constraint checks if type is wrong
          end

          if property_schema[:minimum] && value < property_schema[:minimum]
            errors << "Property '#{key}' must be >= #{property_schema[:minimum]}"
          end

          if property_schema[:maximum] && value > property_schema[:maximum]
            errors << "Property '#{key}' must be <= #{property_schema[:maximum]}"
          end

        when "boolean"
          errors << "Property '#{key}' must be a boolean" unless [true, false].include?(value)

        when "array"
          errors << "Property '#{key}' must be an array" unless value.is_a?(Array)

        when "object"
          errors << "Property '#{key}' must be an object" unless value.is_a?(Hash)
        end
      end

      # Create a response format for structured outputs
      def self.response_format(schema)
        {
          type: "json_object",
          schema: schema
        }
      end
    end
  end
end
