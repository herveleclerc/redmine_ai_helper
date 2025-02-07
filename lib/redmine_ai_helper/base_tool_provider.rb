require "singleton"
require "redmine_ai_helper/agent"
require "redmine_ai_helper/logger"

module RedmineAiHelper
  class BaseToolProvider
    include RedmineAiHelper::Logger
    include Rails.application.routes.url_helpers


    class << self
      def inherited(subclass)
        # puts "######## Adding agent: #{subclass.name}"
        real_class_name = subclass.name.split("::").last
        agent_list = AgentList.instance
        agent_list.add_agent(
          real_class_name.underscore,
          subclass.name,
        )
      end

      def agent_list
        #puts "######## Getting agent list: #{AgentList.instance.agent_list}"
        AgentList.instance.agent_list
      end

      def agent_class_name(name)
        AgentList.instance.agent_class_name(name)
      end

      def list_tools
        raise NotImplementedError
      end
    end


    class AgentList
      include Singleton

      def initialize
        @agents = []
      end

      def add_agent(name, class_name)
        agent = {
          name: name,
          class: class_name,
        }
        # Check if the agent is already in the list
        # If it is, remove it and add the new one
        @agents.delete_if { |a| a[:name] == name }
        @agents << agent
      end

      def agent_list
        @agents
      end
    end

    def self.agent_class_name(agent_name)
      agent = self.agent_list.find { |agent| agent[:name] == agent_name }
      agent[:class] if agent
    end
  end
end
