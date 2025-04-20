# frozen_string_literal: true
require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # RepositoryAgent is a specialized agent for handling Redmine repository-related queries.
    class RepositoryAgent < RedmineAiHelper::BaseAgent
      def backstory
        # TODO: 英語にする
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
