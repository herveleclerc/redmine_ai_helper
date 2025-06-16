# frozen_string_literal: true
require 'open3'
require_relative 'base_transport'

module RedmineAiHelper
  module Transport
    # STDIO-based MCP transport implementation
    # Extracted from existing MCP Tools implementation and adapted for transport abstraction
    class StdioTransport < BaseTransport
      # Custom exception class for execution errors
      class ExecutionError < StandardError; end

      attr_reader :command_array, :env_hash

      # Initialize STDIO transport
      # @param config [Hash] STDIO transport configuration
      def initialize(config)
        super(config)
        @command_array = build_command_array(config)
        @env_hash = config['env'] || {}
        @call_counter = 0
      end

      # Send MCP request via STDIO
      # @param message [Hash] JSON-RPC message
      # @return [Hash] Parsed response
      def send_request(message)
        input_json = message.to_json
        
        stdout, stderr, status = Open3.capture3(@env_hash, *@command_array, stdin_data: "#{input_json}\n")
        
        unless status.success?
          raise ExecutionError, "STDIO command execution error: #{stderr}"
        end
        
        parse_response(stdout)
      rescue => e
        Rails.logger.error "STDIO request error: #{e.message}"
        raise e
      end

      # Close connection (no-op for STDIO)
      def close
        # No special cleanup needed for STDIO transport
      end

      # Check connection status (always true for STDIO)
      # @return [Boolean] Always true
      def connected?
        true
      end

      # Get next call counter (for backward compatibility)
      # @return [Integer] Call counter
      def call_counter_up
        before = @call_counter
        @call_counter += 1
        before
      end

      # Helper method for backward compatibility
      # Send tools/list request to get tool information
      # @return [Array] Tools array
      def load_tools_from_server
        request = build_jsonrpc_message('tools/list')
        response = send_request(request)
        
        tools = response.dig('result', 'tools')
        return [] unless tools
        
        tools.is_a?(Array) ? tools : [tools]
      rescue => e
        Rails.logger.error "Error loading tools from MCP server: #{e.message}"
        []
      end

      # Send tool call request
      # @param tool_name [String] Tool name
      # @param arguments [Hash] Tool arguments
      # @return [Hash] Response
      def call_tool(tool_name, arguments = {})
        request = build_jsonrpc_message('tools/call', {
          'name' => tool_name.to_s,
          'arguments' => arguments
        })
        
        send_request(request)
      end

      # Get transport statistics
      # @return [Hash] Statistics
      def stats
        {
          transport_type: 'stdio',
          command: @command_array.join(' '),
          call_count: @call_counter,
          connected: connected?
        }
      end

      protected

      # Validate configuration
      # @param config [Hash] Configuration to validate
      def validate_config(config)
        super(config)
        
        unless config['command'] || config['args']
          raise ArgumentError, "STDIO transport requires command or args"
        end
      end

      # Build command array from configuration
      # @param config [Hash] Configuration
      # @return [Array<String>] Command array
      def build_command_array(config)
        command = config['command']
        args = config['args'] || []
        
        if command
          [command] + args
        elsif args.any?
          args
        else
          raise ArgumentError, "Command or args not specified"
        end
      end

      private

      # Build JSON-RPC request message (override)
      # @param method [String] Method name
      # @param params [Hash] Parameters
      # @param id [Integer] Request ID
      # @return [Hash] JSON-RPC message
      def build_jsonrpc_message(method, params = {}, id = nil)
        super(method, params, id || call_counter_up)
      end
    end
  end
end