# frozen_string_literal: true
require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # ProjectAgent is a specialized agent for handling Redmine project-related queries.
    class ProjectAgent < RedmineAiHelper::BaseAgent
      def backstory
        # TODO: 英語にする
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
