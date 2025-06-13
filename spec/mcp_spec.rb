# frozen_string_literal: true

require "spec_helper"

RSpec.describe MistralAI::MCP do
  describe "module loading" do
    it "loads all MCP modules without error" do
      expect { require "mistral-ai/mcp" }.not_to raise_error
    end

    it "defines MCP module constants" do
      expect(MistralAI::MCP).to be_a(Module)
      expect(MistralAI::MCP::VERSION).to be_a(String)
    end
  end

  describe "exception classes" do
    it "defines MCP exception hierarchy" do
      expect(MistralAI::MCP::MCPException).to be < MistralAI::Error
      expect(MistralAI::MCP::MCPAuthException).to be < MistralAI::MCP::MCPException
      expect(MistralAI::MCP::MCPConnectionException).to be < MistralAI::MCP::MCPException
      expect(MistralAI::MCP::MCPToolNotFoundException).to be < MistralAI::MCP::MCPException
      expect(MistralAI::MCP::MCPServerException).to be < MistralAI::MCP::MCPException
    end

    it "creates exceptions with proper messages" do
      auth_error = MistralAI::MCP::MCPAuthException.new("test auth error")
      expect(auth_error.message).to eq("test auth error")

      tool_error = MistralAI::MCP::MCPToolNotFoundException.new("test_tool")
      expect(tool_error.message).to eq("Tool 'test_tool' not found")

      server_error = MistralAI::MCP::MCPServerException.new("server error", 500)
      expect(server_error.message).to eq("server error")
      expect(server_error.error_code).to eq(500)
    end
  end

  describe "STDIO parameters" do
    it "creates STDIO server parameters" do
      params = MistralAI::MCP::StdioServerParameters.new(
        command: "python",
        args: ["script.py"],
        env: { "DEBUG" => "true" }
      )

      expect(params.command).to eq("python")
      expect(params.args).to eq(["script.py"])
      expect(params.env).to eq({ "DEBUG" => "true" })
    end

    it "converts to hash" do
      params = MistralAI::MCP::StdioServerParameters.new(command: "node", args: ["server.js"])
      hash = params.to_h

      expect(hash[:command]).to eq("node")
      expect(hash[:args]).to eq(["server.js"])
      expect(hash[:env]).to be_nil
    end
  end

  describe "SSE parameters" do
    it "creates SSE server parameters with defaults" do
      params = MistralAI::MCP::SSEServerParams.new(url: "https://example.com/sse")

      expect(params.url).to eq("https://example.com/sse")
      expect(params.headers).to eq({})
      expect(params.timeout).to eq(5)
      expect(params.sse_read_timeout).to eq(300)
    end

    it "creates SSE server parameters with custom values" do
      params = MistralAI::MCP::SSEServerParams.new(
        url: "https://example.com/sse",
        headers: { "Authorization" => "Bearer token" },
        timeout: 10,
        sse_read_timeout: 600
      )

      expect(params.url).to eq("https://example.com/sse")
      expect(params.headers).to eq({ "Authorization" => "Bearer token" })
      expect(params.timeout).to eq(10)
      expect(params.sse_read_timeout).to eq(600)
    end
  end

  describe "MCP system prompt" do
    it "creates system prompt with defaults" do
      prompt = MistralAI::MCP::MCPSystemPrompt.new

      expect(prompt.description).to be_nil
      expect(prompt.messages).to eq([])
    end

    it "creates system prompt with values" do
      messages = [
        { "role" => "user", "content" => { "type" => "text", "text" => "Hello" } }
      ]
      prompt = MistralAI::MCP::MCPSystemPrompt.new(
        description: "Test prompt",
        messages: messages
      )

      expect(prompt.description).to eq("Test prompt")
      expect(prompt.messages).to eq(messages)
    end

    it "converts to hash" do
      prompt = MistralAI::MCP::MCPSystemPrompt.new(
        description: "Test",
        messages: [{ "role" => "user", "content" => "test" }]
      )
      hash = prompt.to_h

      expect(hash[:description]).to eq("Test")
      expect(hash[:messages]).to eq([{ "role" => "user", "content" => "test" }])
    end
  end

  describe "OAuth2 token" do
    it "creates token from hash with string keys" do
      data = {
        "access_token" => "test_token",
        "token_type" => "Bearer",
        "expires_in" => 3600,
        "refresh_token" => "refresh_token"
      }
      token = MistralAI::MCP::OAuth2Token.new(data)

      expect(token.access_token).to eq("test_token")
      expect(token.token_type).to eq("Bearer")
      expect(token.expires_in).to eq(3600)
      expect(token.refresh_token).to eq("refresh_token")
    end

    it "creates token from hash with symbol keys" do
      data = {
        access_token: "test_token",
        token_type: "Bearer",
        expires_in: 3600
      }
      token = MistralAI::MCP::OAuth2Token.new(data)

      expect(token.access_token).to eq("test_token")
      expect(token.token_type).to eq("Bearer")
      expect(token.expires_in).to eq(3600)
    end

    it "provides hash access to token values" do
      token = MistralAI::MCP::OAuth2Token.new(access_token: "test_token")

      expect(token["access_token"]).to eq("test_token")
      expect(token[:access_token]).to eq("test_token")
    end
  end
end 