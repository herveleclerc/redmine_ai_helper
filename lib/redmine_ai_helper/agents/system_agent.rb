# frozen_string_literal: true
require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # SystemAgent is a specialized agent for handling Redmine system-related queries.
    class SystemAgent < RedmineAiHelper::BaseAgent
      def backstory
        prompt = load_prompt("system_agent/backstory")
        content = prompt.format
        content
      end

      def available_tool_providers
        [RedmineAiHelper::Tools::SystemTools]
      end
    end
  end
end
