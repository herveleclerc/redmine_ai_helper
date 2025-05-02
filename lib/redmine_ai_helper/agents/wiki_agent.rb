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
        [RedmineAiHelper::Tools::WikiTools]
      end
    end
  end
end
