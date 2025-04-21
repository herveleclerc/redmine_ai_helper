require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # BoardAgent is a specialized agent for handling Redmine board-related queries.
    class BoardAgent < RedmineAiHelper::BaseAgent
      def backstory
        # TODO: 英語にする
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのフォオーラムエージェントです。Redmine のフォーラムやフォーラムに投稿されているメッセージに関する問い合わせに答えます。
        EOS
        content
      end

      def available_tool_providers
        [RedmineAiHelper::Tools::BoardTools]
      end
    end
  end
end
