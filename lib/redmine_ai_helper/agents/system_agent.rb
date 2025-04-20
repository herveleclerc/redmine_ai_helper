# frozen_string_literal: true
require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # SystemAgent is a specialized agent for handling Redmine system-related queries.
    class SystemAgent < RedmineAiHelper::BaseAgent
      def backstory
        # TODO: 英語にする
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのシステムエージェントです。Redmine のシステムに関する問い合わせに答えます。システムとは、
          - Redmine の設定
          - インストールされているプラグイン
          などの情報が含まれます。
        EOS
        content
      end

      def available_tool_providers
        [RedmineAiHelper::Tools::SystemTools]
      end
    end
  end
end
