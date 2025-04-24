require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # BoardAgent is a specialized agent for handling Redmine board-related queries.
    class BoardAgent < RedmineAiHelper::BaseAgent
      def backstory
        content = prompt = load_prompt("board_agent/backstory")
        content
      end

      def available_tool_providers
        [RedmineAiHelper::Tools::BoardTools]
      end
    end
  end
end
