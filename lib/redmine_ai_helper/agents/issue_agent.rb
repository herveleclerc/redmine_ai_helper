# frozen_string_literal: true
require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # IssueAgent is a specialized agent for handling Redmine issue-related queries.
    class IssueAgent < RedmineAiHelper::BaseAgent
      def backstory
        search_answer_instruction = I18n.t("ai_helper.prompts.issue_agent.search_answer_instruction")
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
        content = <<~EOS

          ----

          The following issue properties are available for Project ID: #{@project.id}.

          ```json
          #{JSON.pretty_generate(properties)}
          ```
        EOS
        content
      end
    end
  end
end
