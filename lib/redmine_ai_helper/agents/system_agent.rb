require "redmine_ai_helper/base_agent"
require "redmine_ai_helper/agent_response"

module RedmineAiHelper
  module Agents
    class SystemAgent < RedmineAiHelper::BaseAgent
      def self.list_tools()
        list = {
          tools: [
            {
              name: "list_plugins",
              description: "Returns a list of all plugins installed in Redmine.",
              arguments: {},
            },
          ],
        }
        list
      end

      # Returns a list of all plugins installed in Redmine
      def list_plugins(args = {})
        plugins = Redmine::Plugin.all
        plugin_list = []
        plugins.map do |plugin|
          plugin_list <<
          {
            name: plugin.name,
            version: plugin.version,
            author: plugin.author,
            url: plugin.url,
            author_url: plugin.author_url,
          }
        end
        json = { plugins: plugin_list }
        AgentResponse.create_success json
      end
    end
  end
end
