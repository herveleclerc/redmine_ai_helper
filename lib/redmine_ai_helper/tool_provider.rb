require "redmine_ai_helper/llm"
require "redmine_ai_helper/base_tool_provider"
require "redmine_ai_helper/logger"
require "redmine_ai_helper/tool_response"
# このソースファイルがあるディレクトリの下のagents/*_agent.rbファイルをrequireする
Dir[File.join(File.dirname(__FILE__), "agents", "*_agent.rb")].each do |file|
  require file
end

module RedmineAiHelper
  class ToolProvider
    include RedmineAiHelper::Logger

    def initialize(client, model)
      @client = client
      @model = model
    end

    def self.list_tools()
      list = {}

      # puts "#### BaseAgent.agent_list: #{RedmineAiHelper::BaseAgent.agent_list}"
      agents = RedmineAiHelper::BaseToolProvider.agent_list.map do |agent|
        # puts "#### agent: #{agent}"
        begin
          agent_class = Object.const_get(agent[:class])
          {
            name: agent[:name],
            tools: agent_class.send(:list_tools)[:tools],
          }
        rescue => e
          ai_helper_logger.error "agent_name = #{agent[:name]}: #{e.full_message}"
        end
      end
      # puts "#### agents: #{agents}"
      list = { agents: agents }
      json = JSON.pretty_generate(list)
      # puts "#### list_tools: #{json}"
      json
    end

    def call_tool(params = {})
      agent_name = params[:agent_name]
      name = params[:name]
      args = params[:arguments]

      begin
        agent_class_name = RedmineAiHelper::BaseToolProvider.agent_class_name(agent_name)
        return ToolResponse.create_error "Agent not found." if agent_class_name.nil?
        agent = Object.const_get(agent_class_name).new()
      rescue => e
        ai_helper_logger.error "agent_name = #{agent_name}: #{e.full_message}"
        return ToolResponse.create_error "agent_name = #{agent_name}: #{e.message}"
      end

      # Use reflection to call the method named 'name' on this instance, passing 'args' as arguments.
      # If the method does not exist, an exception will be raised.
      if agent.respond_to?(name)
        begin
          response = agent.send(name, args)
        rescue => e
          ai_helper_logger.error e.full_message
          return ToolResponse.create_error e.message
        end
      else
        ai_helper_logger.error "agent_name = #{agent_name}: Method #{name} not found"
        return ToolResponse.create_error "agent_name = #{agent_name}: Method #{name} not found"
      end
      response
    end
  end
end
