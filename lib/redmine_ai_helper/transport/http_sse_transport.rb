# frozen_string_literal: true
require_relative "base_transport"

module RedmineAiHelper
  module Transport
    # HTTP with Server-Sent Events (SSE) MCP transport
    # Following MCP specification: HTTP POST for client-to-server, SSE for server-to-client
    class HttpSseTransport < BaseTransport
      include RedmineAiHelper::Logger
      # Custom exception classes
      class ConnectionError < StandardError; end
      class TimeoutError < StandardError; end
      class ServerError < StandardError; end
      class ClientError < StandardError; end

      attr_reader :base_url, :message_endpoint, :session_id

      # Initialize HTTP transport
      # @param config [Hash] HTTP transport configuration
      def initialize(config)
        super(config)
        @config = config
        @base_url = config["url"]
        @timeout = config["timeout"] || 30
        @reconnect = config["reconnect"] || false
        @max_retries = config["max_retries"] || 3
        @headers = config["headers"] || {}

        @sse_connection = nil
        @message_endpoint = nil
        @session_id = nil
        @http_client = build_http_client
        @connected = false
        @retry_count = 0
      end

      # Establish SSE connection
      def connect
        return if @connected
        @message_endpoint = detect_message_endpoint
        @session_id = SecureRandom.uuid
        @connected = true
        ai_helper_logger.info "Connected to MCP Server: #{@message_endpoint}"
      rescue => e
        ai_helper_logger.error "Failed to connect: #{base_url} #{e.full_message}"
        handle_connection_error(e)
      end

      # Send MCP request
      # @param message [Hash] JSON-RPC message
      # @return [Hash] Parsed response
      def send_request(message)
        begin
          ensure_connected

          response = perform_http_request(message)
          ai_helper_logger.debug "HTTP response: #{response.status} #{response.body}"
          handle_response(response)
        rescue Faraday::TimeoutError => e
          raise TimeoutError, "Request timed out: #{e.message}"
        rescue Faraday::ConnectionFailed => e
          raise ConnectionError, "Connection failed: #{e.message}"
        rescue => e
          ai_helper_logger.error "HTTP request error: #{e.full_message}"
          handle_request_error(e)
        end
      end

      # Close connection
      def close
        close_sse_connection if @sse_connection
        @connected = false
        @message_endpoint = nil
        @session_id = nil
      end

      # Check connection status
      # @return [Boolean] True if connected
      def connected?
        @connected && !@message_endpoint.nil?
      end

      protected

      # Validate configuration
      # @param config [Hash] Configuration to validate
      def validate_config(config)
        super(config)

        raise ArgumentError, "URL is required" unless config["url"]
        raise ArgumentError, "Invalid URL format" unless valid_url?(config["url"])

        if config["timeout"] && config["timeout"] <= 0
          raise ArgumentError, "Timeout must be a positive value"
        end
      end

      # Validate URL format
      # @param url [String] URL to validate
      # @return [Boolean] True if URL is valid
      def valid_url?(url)
        uri = URI.parse(url)
        %w[http https].include?(uri.scheme)
      rescue URI::InvalidURIError
        false
      end

      # Build HTTP client
      # @return [Faraday::Connection] Configured HTTP client
      def build_http_client
        Faraday.new(@base_url) do |f|
          f.request :json
          f.response :json
          f.options.timeout = @timeout
          f.options.open_timeout = @timeout

          # Set headers
          @headers.each do |key, value|
            f.headers[key] = value
          end

          # Configure retry settings
          if defined?(Faraday::Retry)
            f.request :retry, max: 2, interval: 0.5,
                              exceptions: [Faraday::ConnectionFailed, Faraday::TimeoutError]
          end

          f.adapter Faraday.default_adapter
        end
      end

      # Establish SSE connection
      def establish_sse_connection
        Rails.logger.info "Establishing SSE connection using fallback implementation"
        establish_sse_connection_fallback
      end

      # Fallback implementation for SSE connection
      def establish_sse_connection_fallback
        ai_helper_logger.info "Starting SSE connection fallback implementation"
        # Simple SSE implementation (external library recommended for full implementation)
        sse_url = "#{@base_url}/sse"
        @sse_connection = Thread.new do
          begin
            response = @http_client.get(sse_url) do |req|
              req.headers["Accept"] = "text/event-stream"
              req.headers["Cache-Control"] = "no-cache"
            end

            # Process SSE stream (simplified version)
            response.body.each_line do |line|
              next if line.strip.empty?

              if line.start_with?("event:")
                @current_event_type = line.sub("event:", "").strip
              elsif line.start_with?("data:")
                data = line.sub("data:", "").strip
                handle_sse_event(@current_event_type, data)
              end
            end
          rescue => e
            ai_helper_logger.error "SSE connection error: #{e.full_message}"
            handle_sse_error(e)
          end
        end
      end

      # Process SSE events (simplified version without gems)
      # @param event_type [String] Event type
      # @param data [String] Event data
      def handle_sse_event(event_type, data)
        handle_sse_event_data(event_type, data)
      end

      # Process SSE event data for fallback
      # @param event_type [String] Event type
      # @param data [String] Event data
      def handle_sse_event_data(event_type, data)
        case event_type
        when "endpoint"
          endpoint_data = JSON.parse(data)
          @message_endpoint = endpoint_data["url"]
          extract_session_id
        when "message"
          handle_message_event(JSON.parse(data))
        end
      rescue JSON::ParserError => e
        Rails.logger.error "SSE event data JSON parse error: #{e.message}"
      end

      # Process message events
      # @param message [Hash] Message data
      def handle_message_event(message)
        # Process messages from server
        Rails.logger.debug "SSE message received: #{message}"
      end

      # Extract session ID
      def extract_session_id
        # Generate session ID (simple implementation)
        @session_id = SecureRandom.uuid
      end

      # Handle SSE errors
      # @param error [StandardError] SSE error
      def handle_sse_error(error)
        Rails.logger.error "SSE error: #{error.message}"

        if @reconnect && @retry_count < @max_retries
          @retry_count += 1
          Rails.logger.info "SSE reconnection attempt (#{@retry_count}/#{@max_retries})"
          sleep(1)
          establish_sse_connection
        else
          raise ConnectionError, "SSE connection error: #{error.message}"
        end
      end

      # Wait for endpoint event arrival
      def wait_for_endpoint_event
        timeout = @timeout
        start_time = Time.current

        while @message_endpoint.nil? && (Time.current - start_time) < timeout
          sleep(0.1)
        end

        unless @message_endpoint
          raise TimeoutError, "Timeout waiting for endpoint event"
        end
      end

      # Ensure connection is established
      def ensure_connected
        connect unless connected?

        unless connected?
          raise ConnectionError, "Not connected to MCP server"
        end
      end

      # Perform HTTP request
      # @param message [Hash] JSON-RPC message
      # @return [Faraday::Response] HTTP response
      def perform_http_request(message)
        @http_client.post(@message_endpoint) do |req|
          req.headers["Content-Type"] = "application/json"
          req.headers["Accept"] = "application/json, text/event-stream"
          req.headers["Mcp-Session-Id"] = @session_id if @session_id

          # Set Authorization header if authentication token exists
          if @config && @config["authorization_token"]
            req.headers["Authorization"] = @config["authorization_token"]
          end

          req.body = message.to_json
        end
      end

      # Process HTTP response
      # @param response [Faraday::Response] HTTP response
      # @return [Hash] Parsed response
      def handle_response(response)
        case response.status
        when 200..299
          body = response.body.is_a?(String) ? response.body : response.body.to_json
          
          # Check for SSE format response
          if body.start_with?("event:")
            parse_sse_response(body)
          else
            parse_response(body)
          end
        when 400..499
          raise ClientError, "Client error (#{response.status}): #{response.body}"
        when 500..599
          raise ServerError, "Server error (#{response.status}): #{response.body}"
        else
          raise ConnectionError, "Unexpected HTTP status: #{response.status}"
        end
      end

      # Parse SSE format response
      # @param sse_body [String] SSE format response body
      # @return [Hash] Parsed JSON response
      def parse_sse_response(sse_body)
        data_lines = []
        current_event = nil
        
        sse_body.each_line do |line|
          line = line.strip
          next if line.empty?
          
          if line.start_with?("event:")
            current_event = line.sub("event:", "").strip
          elsif line.start_with?("data:")
            data_content = line.sub("data:", "").strip
            data_lines << data_content
          end
        end
        
        # Combine data lines and parse as JSON
        json_data = data_lines.join("")
        parse_response(json_data)
      rescue JSON::ParserError => e
        ai_helper_logger.error "SSE response JSON parse error: #{e.message}"
        raise StandardError, "Invalid SSE JSON response: #{e.message}"
      end

      # Handle request errors
      # @param error [StandardError] Error
      def handle_request_error(error)
        ai_helper_logger.error "Request error: #{error.full_message}"
        raise error
      end

      # Handle connection errors
      # @param error [StandardError] Error
      def handle_connection_error(error)
        ai_helper_logger.error "Connection error: #{error.full_message}"
        @connected = false

        if @reconnect && @retry_count < @max_retries
          @retry_count += 1
          Rails.logger.info "Attempting reconnection (#{@retry_count}/#{@max_retries})"
          sleep(2 ** @retry_count) # Exponential backoff
          connect
        else
          raise ConnectionError, "Connection failed: #{error.message}"
        end
      end

      # Close SSE connection
      def close_sse_connection
        if @sse_connection.respond_to?(:close)
          @sse_connection.close
        elsif @sse_connection.is_a?(Thread)
          @sse_connection.kill
        end
      rescue => e
        Rails.logger.error "SSE connection termination error: #{e.message}"
      ensure
        @sse_connection = nil
      end

      # Detect GitHub MCP server message endpoint
      def detect_message_endpoint
        @base_url.chomp("/")
      end
    end
  end
end
