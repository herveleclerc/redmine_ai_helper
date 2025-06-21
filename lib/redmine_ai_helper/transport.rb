# frozen_string_literal: true

module RedmineAiHelper
  module Transport
    # Transport module provides MCP (Model Context Protocol) transport abstraction
    # Supports both STDIO and HTTP+SSE transports
    
    # Autoload transport classes to avoid circular dependencies
    autoload :BaseTransport, 'redmine_ai_helper/transport/base_transport'
    autoload :StdioTransport, 'redmine_ai_helper/transport/stdio_transport'
    autoload :HttpSseTransport, 'redmine_ai_helper/transport/http_sse_transport'
    autoload :TransportFactory, 'redmine_ai_helper/transport/transport_factory'
    
    # Get list of available transport types
    def self.available_transports
      TransportFactory.supported_transports
    end
    
    # Create transport instance from configuration
    # @param config [Hash] Transport configuration
    # @return [BaseTransport] Transport instance
    def self.create(config)
      TransportFactory.create(config)
    end
    
    # Validate transport configuration
    # @param config [Hash] Configuration to validate
    # @return [Boolean] True if valid
    def self.valid_config?(config)
      TransportFactory.valid_config?(config)
    end
    
    # Determine transport type from configuration
    # @param config [Hash] Configuration
    # @return [String] Transport type
    def self.determine_type(config)
      TransportFactory.determine_transport_type(config)
    end
  end
end