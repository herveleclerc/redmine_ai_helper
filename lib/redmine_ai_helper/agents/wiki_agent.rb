# frozen_string_literal: true
require_relative "../base_agent"

module RedmineAiHelper
  module Agents
    # WikiAgent is a specialized agent for handling Redmine wiki-related queries.
    class WikiAgent < RedmineAiHelper::BaseAgent
      def backstory
        prompt = load_prompt("wiki_agent/backstory")
        content = prompt.format
        content
      end

      def available_tool_providers
        base_tools = [RedmineAiHelper::Tools::WikiTools]
        if AiHelperSetting.vector_search_enabled?
          base_tools.unshift(RedmineAiHelper::Tools::VectorTools)
        end
        base_tools
      end
    end
  end
end
