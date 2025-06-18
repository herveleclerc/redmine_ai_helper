# frozen_string_literal: true
require "redmine_ai_helper/logger"
require "redmine_ai_helper/util/configuration_migrator"

module RedmineAiHelper
  module Util
    # A class that reads config.json and generates tool classes for MCPTools.
    # The Singleton pattern is adopted to avoid generating the same class multiple times.
    # Updated to support the new transport abstraction layer.
    class McpToolsLoader
      include Singleton
      include RedmineAiHelper::Logger

      # Load the configuration file and generate tool classes.
      # @return [Array] An array of tool classes generated from the configuration file.
      def self.load
        loader.generate_tools_instances
      end

      # Retrieves the singleton instance of this class.
      # @return [McpToolsLoader] The singleton instance of this class.
      def self.loader
        McpToolsLoader.instance
      end

      # Generate instances of all MCPTools
      # @return [Array] An array of tool classes generated from the configuration file.
      def generate_tools_instances
        return @list if @list
        
        # Check if the config file exists
        unless File.exist?(config_file)
          ai_helper_logger.warn "MCP config file not found: #{config_file}"
          return []
        end

        # Load and migrate the configuration file
        config = load_and_migrate_config

        mcp_servers = config["mcpServers"]
        return [] unless mcp_servers

        list = []
        # Generate tool classes based on the configuration
        mcp_servers.each do |name, json|
          begin
            # Validate configuration before generating tool class
            unless valid_server_config?(json)
              ai_helper_logger.warn "Invalid configuration for MCP server '#{name}': #{json}"
              next
            end

            tool_class = RedmineAiHelper::Tools::McpTools.generate_tool_class(name: name, json: json)
            list << tool_class
            ai_helper_logger.info "Successfully loaded MCP server '#{name}' with transport '#{json['transport'] || 'stdio'}'"
          rescue => e
            ai_helper_logger.error "Error generating tool class for #{name}: #{e.message}"
            ai_helper_logger.error e.backtrace.join("\n") if ai_helper_logger.respond_to?(:debug?) && ai_helper_logger.debug?
            # Continue with other servers instead of throwing
          end
        end
        @list = list
      end

      # Get access to configuration data for testing
      # @return [Hash] The configuration data
      def config_data
        return {} unless File.exist?(config_file)
        load_and_migrate_config
      end

      # Returns the path to the configuration file.
      def config_file
        @config_file ||= Rails.root.join("config", "ai_helper", "config.json").to_s
      end

      private

      # Load and migrate configuration file
      # @return [Hash] The migrated configuration
      def load_and_migrate_config
        raw_config = JSON.parse(File.read(config_file))
        RedmineAiHelper::Util::ConfigurationMigrator.migrate_config(raw_config)
      rescue JSON::ParserError => e
        ai_helper_logger.error "Invalid JSON in config file: #{e.message}"
        {}
      rescue Errno::ENOENT, Errno::EACCES => e
        ai_helper_logger.error "Cannot read config file: #{e.message}"
        {}
      rescue => e
        ai_helper_logger.error "Error loading config file: #{e.message}"
        {}
      end

      # Validate server configuration
      # @param config [Hash] Server configuration
      # @return [Boolean] True if valid
      def valid_server_config?(config)
        return false unless config.is_a?(Hash)

        transport_type = config['transport'] || determine_legacy_transport(config)
        
        case transport_type
        when 'stdio'
          (!!(config['command'] && !config['command'].to_s.empty?)) || (!!(config['args'] && config['args'].any?))
        when 'http'
          !!(config['url'] && !config['url'].to_s.empty? && valid_url?(config['url']))
        else
          false
        end
      end

      # Determine transport type from legacy configuration
      # @param config [Hash] Configuration
      # @return [String] Transport type
      def determine_legacy_transport(config)
        return 'stdio' unless config.is_a?(Hash)
        
        if config['command'] || config['args']
          'stdio'
        elsif config['url']
          'http'
        else
          'stdio' # Default
        end
      end

      # Validate URL format
      # @param url [String] URL to validate
      # @return [Boolean] True if valid
      def valid_url?(url)
        uri = URI.parse(url)
        %w[http https].include?(uri.scheme)
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
