# frozen_string_literal: true

module RedmineAiHelper
  module Transport
    # Factory class responsible for MCP transport creation
    # Generates appropriate transport instances based on configuration
    class TransportFactory
      # Supported transport types
      SUPPORTED_TRANSPORTS = %w[stdio http].freeze

      class << self
        # Create transport instance based on configuration
        # Ignores transport field and auto-detects from command/url presence
        # @param config [Hash] Transport configuration
        # @return [BaseTransport] Generated transport instance
        # @raise [ArgumentError] If unsupported transport type
        def create(config)
          validate_config(config)
          
          transport_type = determine_transport_type(config)
          
          case transport_type
          when 'stdio'
            create_stdio_transport(config)
          when 'http'
            create_http_transport(config)
          else
            raise ArgumentError, "Unable to determine transport type from configuration: #{config}"
          end
        end

        # Get list of available transport types
        # @return [Array<String>] Supported transport types
        def supported_transports
          SUPPORTED_TRANSPORTS.dup
        end

        # Determine transport type from configuration
        # stdio if command/args exists, http if url exists
        # @param config [Hash] Configuration
        # @return [String] Transport type
        def determine_transport_type(config)
          return 'stdio' unless config.is_a?(Hash)
          
          # HTTP if URL exists
          return 'http' if config['url']
          
          # STDIO if command or args exists
          return 'stdio' if config['command'] || (config['args'] && config['args'].any?)
          
          # Error if cannot determine
          raise ArgumentError, "Cannot determine transport type: configuration must have either 'url' for HTTP or 'command'/'args' for STDIO"
        end

        # Check if transport configuration is valid
        # @param config [Hash] Configuration
        # @return [Boolean] True if valid
        def valid_config?(config)
          return false unless config.is_a?(Hash)
          
          begin
            transport_type = determine_transport_type(config)
            
            case transport_type
            when 'stdio'
              valid_stdio_config?(config)
            when 'http'
              valid_http_config?(config)
            else
              false
            end
          rescue
            false
          end
        end

        private

        # Validate basic configuration
        # @param config [Hash] Configuration to validate
        def validate_config(config)
          raise ArgumentError, "Configuration must be a hash" unless config.is_a?(Hash)
          raise ArgumentError, "Configuration is empty" if config.empty?
        end

        # Create STDIO transport
        # @param config [Hash] Configuration
        # @return [StdioTransport] STDIO transport instance
        def create_stdio_transport(config)
          require_relative 'stdio_transport' unless defined?(StdioTransport)
          StdioTransport.new(config)
        end

        # Create HTTP transport
        # @param config [Hash] Configuration
        # @return [HttpSseTransport] HTTP transport instance
        def create_http_transport(config)
          require_relative 'http_sse_transport' unless defined?(HttpSseTransport)
          HttpSseTransport.new(config)
        end

        # STDIO 設定の妥当性を検証する
        # @param config [Hash] 設定
        # @return [Boolean] 有効な場合はtrue
        def valid_stdio_config?(config)
          config['command'] || (config['args'] && config['args'].any?)
        end

        # HTTP 設定の妥当性を検証する
        # @param config [Hash] 設定
        # @return [Boolean] 有効な場合はtrue
        def valid_http_config?(config)
          return false unless config['url']
          
          begin
            uri = URI.parse(config['url'])
            %w[http https].include?(uri.scheme)
          rescue URI::InvalidURIError
            false
          end
        end
      end

      # インスタンスメソッドとしても利用可能にする
      def create(config)
        self.class.create(config)
      end

      def supported_transports
        self.class.supported_transports
      end

      def determine_transport_type(config)
        self.class.determine_transport_type(config)
      end

      def valid_config?(config)
        self.class.valid_config?(config)
      end
    end
  end
end