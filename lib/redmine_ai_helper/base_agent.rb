require "redmine_ai_helper/agent"
require "redmine_ai_helper/logger"

module RedmineAiHelper
  class BaseAgent
    include RedmineAiHelper::Logger
    include Rails.application.routes.url_helpers
    RedmineAiHelper::BaseAgent::AGENT_LIST = []

    # Add an agent to the list of available agents.
    # name: The name of the agent.
    # class: The class of the agent.
    def self.add_agent(options = {})
      agent = {
        name: options[:name],
        class: options[:class],
      }
      RedmineAiHelper::BaseAgent::AGENT_LIST << agent
    end

    def self.agent_list
      RedmineAiHelper::BaseAgent::AGENT_LIST
    end

    def self.agent_class(name)
      agent = self.agent_list.find { |agent| agent[:name] == name }
      agent[:class] if agent
    end

    def self.list_tools
      raise NotImplementedError
    end
  end
end
