require_relative '../base_agent'
module RedmineAiHelper
  module Agents
    class IssueAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのチケットエージェントです。Redmine のチケットに関する問い合わせに答えます。
          なお、「条件に合ったチケットを探して」「こういう条件のチケット見せて」の様なたくさんのチケット探すタスクの場合には、検索条件を指定したチケット一覧のリンクを返してください。
        EOS
        content
      end

      def available_tool_providers
        ["issue_tool_provider", "project_tool_provider"]
      end
    end
  end
end
