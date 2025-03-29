require_relative '../base_agent'
module RedmineAiHelper
  module Agents
    class BoardAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのフォオーラムエージェントです。Redmine のフォーラムやフォーラムに投稿されているメッセージに関する問い合わせに答えます。
        EOS
        content
      end

      def available_tool_providers
        [RedmineAiHelper::ToolProviders::BoardToolProvider]
      end
    end
  end
end
