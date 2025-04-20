# frozen_string_literal: true
require "redmine_ai_helper/logger"

module RedmineAiHelper
  module Util
    # A class that reads config.json and generates tool classes for MCPTools.
    # The Singleton pattern is adopted to avoid generating the same class multiple times.
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
        return @list if @list and @list.length > 0
        # Check if the config file exists
        unless File.exist?(config_file)
          return []
        end

        # Load the configuration file
        config = JSON.parse(File.read(config_file))

        mcp_servers = config["mcpServers"]
        return [] unless mcp_servers

        list = []
        # Generate tool classes based on the configuration
        mcp_servers.each do |name, json|
          begin
            tool_class = RedmineAiHelper::Tools::McpTools.generate_tool_class(name: name, json: json)
            list << tool_class
          rescue => e
            ai_helper_logger.info "Error generating tool class for #{name}: #{e.message}"
            throw "Error generating tool class for #{name}: #{e.message}"
          end
        end
        @list = list
      end

      # Returns the path to the configuration file.
      def config_file
        @config_file ||= Rails.root.join("config", "ai_helper", "config.json").to_s
      end
    end
  end
end
