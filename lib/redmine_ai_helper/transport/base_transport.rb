# frozen_string_literal: true

module RedmineAiHelper
  module Transport
    # Base class for all MCP transports
    # Defines common interface to be implemented by concrete classes
    class BaseTransport
      attr_reader :config

      # Initialize transport
      # @param config [Hash] Transport configuration
      def initialize(config)
        @config = config
        validate_config(config)
      end

      # Send MCP request
      # @param message [Hash] JSON-RPC message
      # @return [Hash] Response
      # @raise [NotImplementedError] Must be implemented by concrete classes
      def send_request(message)
        raise NotImplementedError, "#{self.class}#send_request must be implemented"
      end

      # Close connection
      # @raise [NotImplementedError] Must be implemented by concrete classes
      def close
        raise NotImplementedError, "#{self.class}#close must be implemented"
      end

      # Establish connection (if needed)
      # Default implementation does nothing
      def connect
        # Default implementation does nothing
      end

      # Return transport type
      # @return [String] Transport type
      def transport_type
        self.class.name.split('::').last.downcase.gsub('transport', '')
      end

      protected

      # Validate configuration
      # @param config [Hash] Configuration to validate  
      # @raise [ArgumentError] If configuration is invalid
      def validate_config(config)
        # Base class performs only basic validation
        raise ArgumentError, "Configuration must be a hash" unless config.is_a?(Hash)
      end

      # Generate JSON-RPC request ID
      # @return [Integer] Unique request ID
      def generate_request_id
        @request_id_counter ||= 0
        @request_id_counter += 1
      end

      # Parse response and check for errors
      # @param response_text [String] JSON response text
      # @return [Hash] Parsed response
      # @raise [StandardError] If error response
      def parse_response(response_text)
        response = JSON.parse(response_text)
        
        if response['error']
          error = response['error']
          raise StandardError, "MCP Error (#{error['code']}): #{error['message']}"
        end

        response
      rescue JSON::ParserError => e
        raise StandardError, "Invalid JSON response: #{e.message}"
      end

      # Build JSON-RPC message
      # @param method [String] Method name
      # @param params [Hash] Parameters
      # @param id [Integer] Request ID (auto-generated if omitted)
      # @return [Hash] JSON-RPC message
      def build_jsonrpc_message(method, params = {}, id = nil)
        {
          'jsonrpc' => '2.0',
          'method' => method,
          'params' => params,
          'id' => id || generate_request_id
        }
      end
    end
  end
end