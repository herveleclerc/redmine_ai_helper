require_relative '../base_agent'
module RedmineAiHelper
  module Agents
    class WikiAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのWikiエージェントです。Redmine のWikiに関する問い合わせに答えます。
        EOS
        content
      end

      def available_tool_providers
        [RedmineAiHelper::Tools::WikiTools]
      end
    end
  end
end
