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
        ["wiki_tool_provider"]
      end
    end
  end
end
