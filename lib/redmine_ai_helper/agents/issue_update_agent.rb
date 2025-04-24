# frozen_string_literal: true
require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # IssueUpdateAgent is a specialized agent for handling Redmine issue updates.
    class IssueUpdateAgent < RedmineAiHelper::BaseAgent
      def backstory
        # TODO: 英語にする
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのチケットアップデートエージェントです。Redmine のチケットの作成や、更新を行います。また、チケットのコメントの追加も行います。チケットの情報取得は行いません。
          --
          注意事項:
          チケットの更新やコメントの追加においては、指示された通りに更新をすることはできますが、回答案や更新案を作成することはできません。

          #{issue_properties}
        EOS
        content
      end

      def available_tool_providers
        [
          RedmineAiHelper::Tools::IssueTools,
          RedmineAiHelper::Tools::IssueUpdateTools,
          RedmineAiHelper::Tools::ProjectTools,
          RedmineAiHelper::Tools::UserTools,
        ]
      end

      private

      def issue_properties
        return "" unless @project
        provider = RedmineAiHelper::Tools::IssueTools.new
        properties = provider.capable_issue_properties(project_id: @project.id)
        content = <<~EOS
          ----
          The following issue properties are available for Project ID: #{@project.id}.
          #{properties}
        EOS
        content
      end
    end
  end
end
