# frozen_string_literal: true
require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # IssueAgent is a specialized agent for handling Redmine issue-related queries.
    class IssueAgent < RedmineAiHelper::BaseAgent
      def backstory
        # TODO: 英語にする
        search_answer_instruction = "なお、「条件に合ったチケットを探して」「こういう条件のチケット見せて」の様な複数のチケット探すタスクの場合には、チケット検索のURLを返してください。"
        search_answer_instruction = "" if vector_db_enabled?
        prompt = load_prompt("issue_agent/backstory")
        prompt.format(issue_properties: issue_properties, search_answer_instruction: search_answer_instruction)
      end

      def available_tool_providers
        base_tools = [
          RedmineAiHelper::Tools::IssueTools,
          RedmineAiHelper::Tools::ProjectTools,
          RedmineAiHelper::Tools::UserTools,
          RedmineAiHelper::Tools::IssueSearchTools,
        ]
        if vector_db_enabled?
          base_tools.unshift(RedmineAiHelper::Tools::VectorTools)
        end

        base_tools
      end

      private

      # Check if vector database is enabled
      def vector_db_enabled?
        setting = AiHelperSetting.find_or_create
        setting.vector_search_enabled
      end

      # Generate a available issue properties string
      def issue_properties
        return "" unless @project
        provider = RedmineAiHelper::Tools::IssueTools.new
        properties = provider.capable_issue_properties(project_id: @project.id)
        # TODO: 英語にする
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
