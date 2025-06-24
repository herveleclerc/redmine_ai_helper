# frozen_string_literal: true
require "redmine_ai_helper/base_agent"

module RedmineAiHelper
  module Agents
    # MCPAgent is a specialized agent for handling tasks using the Model Context Protocol (MCP).
    # This agent is now disabled in favor of dynamically generated SubMcpAgent classes.
    class McpAgent < RedmineAiHelper::BaseAgent
      def role
        "mcp_agent"
      end

      def available_tool_providers
        list = Util::McpToolsLoader.load
        list
      end

      def backstory
        prompt = load_prompt("mcp_agent/backstory")
        content = prompt.format
        content
      end

      # McpAgent is now always disabled to prevent conflicts with SubMcpAgent classes
      # @return [Boolean] always returns false
      def enabled?
        false
      end

      # Dynamically generate SubMcpAgent classes for each MCP server
      # This method should be called during application initialization
      def self.generate_sub_agents
        return if @sub_agents_generated

        config_loader = Util::McpToolsLoader.instance
        config_data = config_loader.config_data
        mcp_servers = config_data["mcpServers"]

        return unless mcp_servers

        agent_counter = 1

        mcp_servers.each do |server_name, server_config|
          begin
            # Validate server configuration
            next unless config_loader.send(:valid_server_config?, server_config)

            # Generate class name
            class_name = "AiHelperMcp#{agent_counter}"

            # Check if class already exists to avoid redefinition warnings
            if Object.const_defined?(class_name)
              agent_counter += 1
              next
            end

            # Create dynamic SubMcpAgent class
            sub_agent_class = Class.new(RedmineAiHelper::BaseAgent) do
              define_method :role do
                class_name.underscore
              end

              define_method :available_tool_providers do
                # Load only the tools for this specific MCP server
                tool_class = RedmineAiHelper::Tools::McpTools.generate_tool_class(
                  name: server_name,
                  json: server_config,
                )

                [tool_class]
              rescue => e
                # Use safe logging since this is inside a dynamic class
                begin
                  RedmineAiHelper::CustomLogger.instance.error("Error loading tools for MCP server '#{server_name}': #{e.message}")
                rescue
                  # Fallback to puts if logger is not available
                  puts "Error loading tools for MCP server '#{server_name}': #{e.message}"
                end
                []
              end

              define_method :backstory do
                # Generate backstory with available tools information
                tools_list = available_tools
                tools_info = ""

                if tools_list.is_a?(Array) && !tools_list.empty?
                  # available_tools returns an array of tool schema arrays
                  tools_list.each do |tool_schemas|
                    if tool_schemas.is_a?(Array)
                      tool_schemas.each do |tool|
                        if tool.is_a?(Hash) && tool.dig(:function, :name) && tool.dig(:function, :description)
                          function_name = tool.dig(:function, :name)
                          description = tool.dig(:function, :description)
                          tools_info += "- **#{function_name}**: #{description}\n"
                        end
                      end
                    end
                  end
                else
                  tools_info = "- No tools available\n"
                end

                "I am an AI agent specialized in using the #{server_name} MCP server.\n" \
                "I have access to the following tools:\n" \
                "#{tools_info}\n" \
                "I can help you with tasks that require interaction with #{server_name} services."
              end

              define_method :enabled? do
                true
              end

              # Override class name for agent registration
              define_singleton_method :name do
                class_name
              end

              define_singleton_method :to_s do
                class_name
              end

              # Set instance variable to remember the intended class name
              @intended_class_name = class_name
            end

            # Set the class as a constant to make it accessible
            Object.const_set(class_name, sub_agent_class)

            # Register the dynamic class now that it has a proper name
            RedmineAiHelper::BaseAgent.register_pending_dynamic_class(sub_agent_class, class_name)

            safe_log_debug("Created and registered SubMcpAgent: #{class_name} (agent_name: #{class_name.underscore})")

            agent_counter += 1
          rescue => e
            safe_log_error("Error generating SubMcpAgent for '#{server_name}': #{e.message}")
          end
        end

        @sub_agents_generated = true
      end

      private

      # Safe logging methods that work in test environment
      def self.safe_log_debug(message)
        begin
          RedmineAiHelper::CustomLogger.instance.debug(message)
        rescue
          puts message
        end
      end

      def self.safe_log_error(message)
        begin
          RedmineAiHelper::CustomLogger.instance.error(message)
        rescue
          puts "ERROR: #{message}"
        end
      end
    end
  end
end
