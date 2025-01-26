require "redmine_ai_helper/llm"
require "redmine_ai_helper/base_agent"
# このソースファイルがあるディレクトリの下のagents/*_agent.rbファイルをrequireする
Dir[File.join(File.dirname(__FILE__), "agents", "*_agent.rb")].each do |file|
  require file
end

module RedmineAiHelper
  class Agent
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
        response = agent.send(name, args)
      else
        raise "Method #{name} not found"
      end
      response
    end
  end
end
