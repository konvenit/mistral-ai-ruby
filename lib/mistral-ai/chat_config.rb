# frozen_string_literal: true

require "json"
require "yaml"

module MistralAI
  # Configuration manager for chat interface
  class ChatConfig
    class ConfigurationError < StandardError; end

    attr_reader :mcp_settings, :system_prompt

    def initialize
      @mcp_settings = nil
      @system_prompt = nil
    end

    # Load MCP settings from a file (JSON or YAML)
    def load_mcp_settings(file_path)
      return nil unless file_path && File.exist?(file_path)

      begin
        content = File.read(file_path)
        
        case File.extname(file_path).downcase
        when ".json"
          @mcp_settings = JSON.parse(content)
        when ".yml", ".yaml"
          @mcp_settings = YAML.safe_load(content)
        else
          # Try to parse as JSON first, then YAML
          begin
            @mcp_settings = JSON.parse(content)
          rescue JSON::ParserError
            @mcp_settings = YAML.safe_load(content)
          end
        end

        validate_mcp_settings(@mcp_settings)
        @mcp_settings
      rescue => e
        raise ConfigurationError, "Failed to load MCP settings from #{file_path}: #{e.message}"
      end
    end

    # Load system prompt from a file
    def load_system_prompt(file_path)
      return nil unless file_path && File.exist?(file_path)

      begin
        @system_prompt = File.read(file_path).strip
        
        if @system_prompt.empty?
          raise ConfigurationError, "System prompt file is empty"
        end
        
        @system_prompt
      rescue => e
        raise ConfigurationError, "Failed to load system prompt from #{file_path}: #{e.message}"
      end
    end

    # Parse MCP servers from command line arguments
    def self.parse_mcp_servers(servers_input)
      return [] unless servers_input

      if servers_input.is_a?(String)
        # Split by comma and clean up whitespace
        servers_input.split(',').map(&:strip).reject(&:empty?)
      elsif servers_input.is_a?(Array)
        servers_input.map(&:to_s).map(&:strip).reject(&:empty?)
      else
        []
      end
    end

    # Validate MCP settings structure
    def validate_mcp_settings(settings)
      return unless settings

      unless settings.is_a?(Hash)
        raise ConfigurationError, "MCP settings must be a hash/object"
      end

      # Check for common MCP configuration keys
      valid_keys = %w[servers transport timeout max_retries auth capabilities]
      
      settings.each_key do |key|
        unless valid_keys.include?(key.to_s)
          puts "⚠️  Warning: Unknown MCP setting key '#{key}'"
        end
      end

      # Validate servers configuration if present
      if settings["servers"] || settings[:servers]
        servers = settings["servers"] || settings[:servers]
        unless servers.is_a?(Array) || servers.is_a?(Hash)
          raise ConfigurationError, "MCP servers configuration must be an array or hash"
        end
      end
    end

    # Get a sample MCP configuration
    def self.sample_mcp_config
      {
        "servers" => [
          {
            "name" => "filesystem",
            "command" => "npx",
            "args" => ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/directory"],
            "env" => {}
          },
          {
            "name" => "web-search", 
            "command" => "npx",
            "args" => ["-y", "@modelcontextprotocol/server-web-search"],
            "env" => {
              "GOOGLE_API_KEY" => "your-api-key",
              "GOOGLE_CSE_ID" => "your-cse-id"
            }
          }
        ],
        "transport" => "stdio",
        "timeout" => 30,
        "max_retries" => 3
      }
    end

    # Get a sample system prompt
    def self.sample_system_prompt
      <<~PROMPT
        You are a helpful AI assistant. You should:
        
        1. Be concise and clear in your responses
        2. Ask clarifying questions when needed
        3. Provide examples when explaining concepts
        4. Be honest about what you don't know
        5. Focus on being helpful and accurate
        
        Always maintain a friendly and professional tone.
      PROMPT
    end

    # Generate sample configuration files
    def self.generate_sample_files(directory = ".")
      # Generate sample MCP config
      mcp_config_path = File.join(directory, "mcp_config.json")
      unless File.exist?(mcp_config_path)
        File.write(mcp_config_path, JSON.pretty_generate(sample_mcp_config))
        puts "📝 Generated sample MCP configuration: #{mcp_config_path}"
      end

      # Generate sample system prompt
      system_prompt_path = File.join(directory, "system_prompt.txt")
      unless File.exist?(system_prompt_path)
        File.write(system_prompt_path, sample_system_prompt)
        puts "📝 Generated sample system prompt: #{system_prompt_path}"
      end

      { mcp_config: mcp_config_path, system_prompt: system_prompt_path }
    end
  end
end 