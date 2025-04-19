require "redmine_ai_helper/logger"

module RedmineAiHelper
  module Util
    class McpToolsLoader
      include Singleton
      include RedmineAiHelper::Logger

      def self.load
        loader.generate_tools_instances
      end

      def self.loader
        McpToolsLoader.instance
      end

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

      def config_file
        @config_file ||= Rails.root.join("config", "ai_helper", "config.json").to_s
      end
    end
  end
end
