# frozen_string_literal: true
require "redmine_ai_helper/base_agent"

module RedmineAiHelper
  module Agents
    # MCPAgent is a specialized agent for handling tasks using the Model Context Protocol (MCP).
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
    end
  end
end
