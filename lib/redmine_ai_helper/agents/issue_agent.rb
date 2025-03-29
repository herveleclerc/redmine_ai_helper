require_relative '../base_agent'

module RedmineAiHelper
  module Agents
    class IssueAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = <<~EOS
          あなたは RedmineAIHelper プラグインのチケットエージェントです。Redmine のチケットに関する問い合わせに答えます。
          また、チケットの作成案や更新案などを作成し、実際にデータベースに登録する前に検証することもできます。  ただしチケットの作成やチケットの更新をすることはできません。
          なお、「条件に合ったチケットを探して」「こういう条件のチケット見せて」の様な複数のチケット探すタスクの場合には、チケット検索のURLを返してください。

          #{issue_properties}
        EOS
        content
      end

      def available_tool_providers
        [
          RedmineAiHelper::Tools::IssueToolProvider,
          RedmineAiHelper::Tools::ProjectToolProvider,
          RedmineAiHelper::Tools::UserToolProvider
        ]
      end

      private
      def issue_properties
        return "" unless @project
        provider = RedmineAiHelper::Tools::IssueToolProvider.new
        properties = provider.capable_issue_properties(project_id: @project.id)
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
