require_relative '../base_agent'
require_relative '../tool_providers/issue_tool_provider'
module RedmineAiHelper
  module Agents
    class IssueUpdateAgent < RedmineAiHelper::BaseAgent
      def backstory
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
        ["issue_tool_provider", "issue_update_tool_provider", "project_tool_provider", "user_tool_provider"]
      end

      private
      def issue_properties
        return "" unless @project
        provider = RedmineAiHelper::ToolProviders::IssueToolProvider.new
        properties = provider.capable_issue_properties({project_id: @project.id})
        content = <<~EOS
          ----
          プロジェクトID: #{@project.id} で指定可能なチケットのプロパティは以下の通りです。
          #{properties}
        EOS
        content
      end
    end
  end
end
