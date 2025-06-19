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

      # Generate a summary of the given wiki page with optional streaming support
      # @param wiki_page [WikiPage] The wiki page to summarize
      # @param stream_proc [Proc] Optional callback proc for streaming content
      # @return [String] The summary content
      def wiki_summary(wiki_page:, stream_proc: nil)
        prompt = load_prompt("wiki_agent/summary")
        prompt_text = prompt.format(
          title: wiki_page.title,
          content: wiki_page.content.text,
          project_name: wiki_page.wiki.project.name
        )
        
        message = { role: "user", content: prompt_text }
        messages = [message]
        chat(messages, {}, stream_proc)
      end
    end
  end
end
