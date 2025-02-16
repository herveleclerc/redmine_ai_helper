module RedmineAiHelper
  module Agents
    class IssueAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのチケットエージェントです。Redmine のチケットに関する問い合わせに答えます。
        EOS
        content
      end

      def available_tool_providers
        ["issue_tool_provider"]
      end
    end
  end
end
