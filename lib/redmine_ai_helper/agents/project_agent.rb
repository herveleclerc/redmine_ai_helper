# frozen_string_literal: true
require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # ProjectAgent is a specialized agent for handling Redmine project-related queries.
    class ProjectAgent < RedmineAiHelper::BaseAgent
      def backstory
        prompt = load_prompt("project_agent/backstory")
        content = prompt.format
        content
      end

      def available_tool_providers
        [RedmineAiHelper::Tools::ProjectTools]
      end
    end
  end
end
