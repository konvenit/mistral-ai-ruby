# frozen_string_literal: true

require_relative "lib/mistral_ai/version"

Gem::Specification.new do |spec|
  spec.name = "mistral_ai"
  spec.version = MistralAI::VERSION
  spec.authors = ["Mistral AI"]
  spec.email = ["support@mistral.ai"]

  spec.summary = "Ruby client for the Mistral AI API"
  spec.description = "A Ruby client library for accessing the Mistral AI API, including chat completions, agents, and streaming support."
  spec.homepage = "https://github.com/mistralai/client-ruby"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mistralai/client-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/mistralai/client-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Core dependencies
  spec.add_dependency "faraday", ">= 1.0", "< 3.0"
  spec.add_dependency "faraday-retry", "~> 2.0"

  # MCP (Model Context Protocol) support - optional dependency
  spec.add_dependency "mcp", "~> 0.1", ">= 0.1.0"

  # Development dependencies
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 2.20"
  spec.add_development_dependency "vcr", "~> 6.1"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "yard", "~> 0.9"

  # For better JSON performance (optional)
  spec.add_development_dependency "oj", "~> 3.13"
  
  # For SSE MCP example
  spec.add_development_dependency "webrick", "~> 1.7"
  
  spec.metadata["rubygems_mfa_required"] = "true"
end
