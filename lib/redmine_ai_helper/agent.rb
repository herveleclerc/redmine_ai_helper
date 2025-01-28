require "redmine_ai_helper/llm"
require "redmine_ai_helper/base_agent"
require "redmine_ai_helper/logger"
require "redmine_ai_helper/agent_response"
# このソースファイルがあるディレクトリの下のagents/*_agent.rbファイルをrequireする
Dir[File.join(File.dirname(__FILE__), "agents", "*_agent.rb")].each do |file|
  require file
end

module RedmineAiHelper
  class Agent
    include RedmineAiHelper::Logger

    def initialize(client, model)
      @client = client
      @model = model
    end

    def self.list_tools()
      list = {}
      agents = []
      RedmineAiHelper::BaseAgent.agent_list.each do |agent|
        agents << {
          name: agent[:name],
          tools: agent[:class].list_tools(),
        }
      end
      list = { agents: agents }
      JSON.pretty_generate(list)
    end

    def call_tool(params = {})
      agent_name = params[:agent_name]
      name = params[:name]
      args = params[:arguments]

      agent = RedmineAiHelper::BaseAgent.agent_class(agent_name).new

      # Use reflection to call the method named 'name' on this instance, passing 'args' as arguments.
      # If the method does not exist, an exception will be raised.
      if agent.respond_to?(name)
        begin
          response = agent.send(name, args)
        rescue => e
          ai_helper_logger.error e.full_message
          return AgentResponse.create_error e.message
        end
      else
        ai_helper_logger.error "Method #{name} not found"
        return AgentResponse.create_error "Method #{name} not found"
      end
      response
    end
  end
end
