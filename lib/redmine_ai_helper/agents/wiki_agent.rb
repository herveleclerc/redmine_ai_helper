# frozen_string_literal: true
require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # WikiAgent is a specialized agent for handling Redmine wiki-related queries.
    class WikiAgent < RedmineAiHelper::BaseAgent
      def backstory
        # TODO: 英語にする
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
