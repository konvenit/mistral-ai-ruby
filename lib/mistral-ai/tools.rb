# frozen_string_literal: true

module MistralAI
  module Tools
    # Base class for all tool types
    class BaseTool
      attr_reader :type

      def initialize(type:)
        @type = type
        validate!
      end

      def to_h
        raise NotImplementedError, "Subclasses must implement to_h"
      end

      def to_json(*args)
        to_h.to_json(*args)
      end

      private

      def validate!
        raise ArgumentError, "Tool type cannot be nil or empty" if type.nil? || type.strip.empty?
      end
    end

    # Function tool for defining callable functions
    class FunctionTool < BaseTool
      attr_reader :function

      def initialize(name:, description: nil, parameters: nil)
        super(type: "function")
        @function = FunctionDefinition.new(
          name: name,
          description: description,
          parameters: parameters
        )
      end

      def to_h
        {
          type: type,
          function: function.to_h
        }
      end

      def name
        function.name
      end

      def description
        function.description
      end

      def parameters
        function.parameters
      end
    end

    # Function definition for tools
    class FunctionDefinition
      attr_reader :name, :description, :parameters

      def initialize(name:, description: nil, parameters: nil)
        @name = name
        @description = description
        @parameters = parameters || default_parameters
        validate!
      end

      def to_h
        hash = { name: name }
        hash[:description] = description if description
        hash[:parameters] = parameters if parameters && !parameters.empty?
        hash
      end

      private

      def validate!
        raise ArgumentError, "Function name cannot be nil or empty" if name.nil? || name.strip.empty?
        raise ArgumentError, "Function name must be a valid identifier" unless valid_name?

        validate_parameters! if parameters
      end

      def valid_name?
        name =~ /\A[a-zA-Z_][a-zA-Z0-9_]*\z/
      end

      def validate_parameters!
        raise ArgumentError, "Parameters must be a hash (JSON Schema)" unless parameters.is_a?(Hash)

        # Basic JSON Schema validation
        return unless parameters[:type] && parameters[:type] != "object"

        raise ArgumentError, "Function parameters must have type 'object'"
      end

      def default_parameters
        {
          type: "object",
          properties: {},
          required: []
        }
      end
    end

    # Tool choice specification
    class ToolChoice
      AUTO = "auto"
      NONE = "none"

      attr_reader :choice_type, :function_name

      def self.auto
        new(AUTO)
      end

      def self.none
        new(NONE)
      end

      def self.function(name)
        new("function", function_name: name)
      end

      def initialize(choice_type, function_name: nil)
        @choice_type = choice_type
        @function_name = function_name
        validate!
      end

      def to_h
        case choice_type
        when AUTO, NONE
          choice_type
        when "function"
          {
            type: "function",
            function: { name: function_name }
          }
        else
          choice_type
        end
      end

      def auto?
        choice_type == AUTO
      end

      def none?
        choice_type == NONE
      end

      def function?
        choice_type == "function"
      end

      private

      def validate!
        valid_types = [AUTO, NONE, "function"]
        raise ArgumentError, "Invalid tool choice type: #{choice_type}" unless valid_types.include?(choice_type)

        return unless function? && (function_name.nil? || function_name.strip.empty?)

        raise ArgumentError, "Function name required for function tool choice"
      end
    end

    # Tool call result for function execution responses
    class ToolCall
      attr_reader :id, :type, :function

      def initialize(id:, type:, function:)
        @id = id
        @type = type
        @function = function
        validate!
      end

      def to_h
        {
          id: id,
          type: type,
          function: function
        }
      end

      def function_name
        function[:name] if function.is_a?(Hash)
      end

      def function_arguments
        function[:arguments] if function.is_a?(Hash)
      end

      def parsed_arguments
        return {} unless function_arguments

        if function_arguments.is_a?(String)
          JSON.parse(function_arguments)
        else
          function_arguments
        end
      rescue JSON::ParserError
        {}
      end

      private

      def validate!
        raise ArgumentError, "Tool call ID cannot be nil or empty" if id.nil? || id.strip.empty?
        raise ArgumentError, "Tool call type cannot be nil or empty" if type.nil? || type.strip.empty?
        raise ArgumentError, "Tool call function cannot be nil" if function.nil?
      end
    end

    # Builder for creating tools with a fluent interface
    class ToolBuilder
      def self.function(name, &block)
        builder = new(name)
        builder.instance_eval(&block) if block
        builder.build
      end

      def initialize(name)
        @name = name
        @description = nil
        @parameters = {
          type: "object",
          properties: {},
          required: []
        }
      end

      def description(desc)
        @description = desc
        self
      end

      def parameter(name, type:, description: nil, required: false, **options)
        @parameters[:properties][name] = {
          type: type,
          description: description
        }.merge(options).compact

        @parameters[:required] << name if required
        self
      end

      def string_parameter(name, description: nil, required: false, enum: nil)
        options = {}
        options[:enum] = enum if enum
        parameter(name, type: "string", description: description, required: required, **options)
      end

      def number_parameter(name, description: nil, required: false, minimum: nil, maximum: nil)
        options = {}
        options[:minimum] = minimum if minimum
        options[:maximum] = maximum if maximum
        parameter(name, type: "number", description: description, required: required, **options)
      end

      def integer_parameter(name, description: nil, required: false, minimum: nil, maximum: nil)
        options = {}
        options[:minimum] = minimum if minimum
        options[:maximum] = maximum if maximum
        parameter(name, type: "integer", description: description, required: required, **options)
      end

      def boolean_parameter(name, description: nil, required: false)
        parameter(name, type: "boolean", description: description, required: required)
      end

      def array_parameter(name, description: nil, required: false, items: nil)
        options = {}
        options[:items] = items if items
        parameter(name, type: "array", description: description, required: required, **options)
      end

      def object_parameter(name, description: nil, required: false, properties: nil)
        options = {}
        options[:properties] = properties if properties
        parameter(name, type: "object", description: description, required: required, **options)
      end

      def build
        FunctionTool.new(
          name: @name,
          description: @description,
          parameters: @parameters
        )
      end
    end

    # Utility methods for tool operations
    module ToolUtils
      # Extract tool calls from a chat response
      def self.extract_tool_calls(response)
        return [] unless response&.message&.tool_calls

        response.message.tool_calls.filter_map do |tool_call_data|
          # Ensure we have the required fields
          id = tool_call_data[:id] || tool_call_data["id"]
          type = tool_call_data[:type] || tool_call_data["type"]
          function = tool_call_data[:function] || tool_call_data["function"]

          # Skip if missing required fields
          next unless id && type && function

          begin
            ToolCall.new(
              id: id,
              type: type,
              function: function
            )
          rescue ArgumentError => e
            # Log the error and skip this tool call
            puts "Warning: Skipping invalid tool call: #{e.message}" if defined?(Rails) && Rails.env.development?
            nil
          end
        end
      end

      # Create a tool message for responding to a tool call
      def self.create_tool_message(tool_call_id:, content:)
        MistralAI::Messages::ToolMessage.new(
          content: content,
          tool_call_id: tool_call_id
        )
      end

      # Validate tool definitions
      def self.validate_tools(tools)
        return if tools.nil? || tools.empty?

        raise ArgumentError, "Tools must be an array" unless tools.is_a?(Array)

        tools.each_with_index do |tool, index|
          validate_tool(tool, index)
        end
      end

      # Validate a single tool definition
      def self.validate_tool(tool, index = nil)
        context = index ? " at index #{index}" : ""

        case tool
        when BaseTool
          # Already validated
        when Hash
          validate_tool_hash(tool, context)
        else
          raise ArgumentError, "Invalid tool type#{context}: #{tool.class}"
        end
      end

      def self.validate_tool_hash(tool, context)
        # Support both string and symbol keys for flexibility
        type_key = tool["type"] || tool[:type]
        function_key = tool["function"] || tool[:function]

        raise ArgumentError, "Tool#{context} must have 'type' and 'function' keys" unless type_key && function_key

        raise ArgumentError, "Tool#{context} type must be 'function'" unless type_key == "function"

        function = function_key
        return if function.is_a?(Hash) && (function["name"] || function[:name])

        raise ArgumentError, "Tool#{context} function must have 'name'"
      end
    end
  end
end
