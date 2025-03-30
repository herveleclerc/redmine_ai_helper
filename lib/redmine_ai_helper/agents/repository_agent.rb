require_relative '../base_agent'
module RedmineAiHelper
  module Agents
    class RepositoryAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのリポジトリトエージェントです。Redmine のリポジトリに関する問い合わせに答えます。
        EOS
        content
      end

      def available_tool_providers
        [RedmineAiHelper::Tools::RepositoryTools]
      end
    end
  end
end
