require_relative '../base_agent'
module RedmineAiHelper
  module Agents
    class SystemAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのシステムエージェントです。Redmine のシステムに関する問い合わせに答えます。システムとは、
          - Redmine の設定
          - インストールされているプラグイン
          などの情報が含まれます。
        EOS
        content
      end

      def available_tool_providers
        [RedmineAiHelper::ToolProviders::SystemToolProvider]
      end
    end
  end
end
