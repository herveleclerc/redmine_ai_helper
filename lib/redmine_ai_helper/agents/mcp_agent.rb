require "redmine_ai_helper/base_agent"

module RedmineAiHelper
  module Agents
    class McpAgent < RedmineAiHelper::BaseAgent
      def role
        "mcp_agent"
      end

      def available_tool_providers
        list = Util::McpToolsLoader.load
        list
      end

      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインの MCP エージェントです。
          このRedmineAIHelper プラグインは、MCP (Model Context Protocol) を使用して、さまざまなツールを利用することができます。
          MCPは、AIモデルが外部のツールやサービスと連携するためのプロトコルです。
          MCPを使用することで、あなたはRedmineとは関係のない様々たタスクを実行することができます。
        EOS
        content
      end
    end
  end
end
