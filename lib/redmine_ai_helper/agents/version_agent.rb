# frozen_string_literal: true
require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # VersionAgent is a specialized agent for handling Redmine version-related queries.
    class VersionAgent < RedmineAiHelper::BaseAgent
      def backstory
        # TODO: 英語にする
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのバージョンエージェントです。Redmine のプロジェクトのロードマップやバージョンに関する問い合わせに答えます。
        EOS
        content
      end

      def available_tool_providers
        [RedmineAiHelper::Tools::VersionTools]
      end
    end
  end
end
