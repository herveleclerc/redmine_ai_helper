require_relative '../base_agent'
module RedmineAiHelper
  module Agents
    class ProjectAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのプロジェクトエージェントです。Redmine のプロジェクトに関する問い合わせに答えます。
        EOS
        content
      end

      def available_tool_providers
        [RedmineAiHelper::Tools::ProjectTools]
      end
    end
  end
end
