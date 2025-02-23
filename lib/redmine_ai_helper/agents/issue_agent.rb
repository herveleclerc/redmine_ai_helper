require_relative '../base_agent'
require_relative '../tool_providers/issue_tool_provider'
module RedmineAiHelper
  module Agents
    class IssueAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのチケットエージェントです。Redmine のチケットに関する問い合わせに答えます。また、チケットの更新やコメントの追加などの操作も行います。また、チケットの作成案や更新案などを実際にデータベースに登録する前に検証することもできます。
          なお、「条件に合ったチケットを探して」「こういう条件のチケット見せて」の様な複数のチケット探すタスクの場合には、チケット検索のURLを返してください。
          --
          注意事項:
          チケットの更新やコメントの追加においては、指示された通りに更新をすることはできますが、回答案や更新案を作成することはできません。

          チケットを更新するタスクを複数ステップに分解する際、同じチケットを2回以上更新することは避けてください。同じチケットを更新するタスクが複数回ある場合には、それらのタスクを1つのタスクにまとめてください。

          #{issue_properties}
        EOS
        content
      end

      def available_tool_providers
        ["issue_tool_provider", "project_tool_provider", "user_tool_provider"]
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
