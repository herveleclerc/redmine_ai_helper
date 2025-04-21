# frozen_string_literal: true
require "redmine_ai_helper/logger"
require "redmine_ai_helper/assistant"

# Without this, Langchain logs will be output excessively
Langchain.logger.level = Logger::ERROR

module RedmineAiHelper
  # Base class for all agents.
  class BaseAgent
    attr_accessor :llm_type, :llm_provider, :client
    include RedmineAiHelper::Logger

    class << self
      # This method is automatically called when a subclass agent is loaded.
      # Adds the agent to the list.
      # @param subclass [Class] The subclass that is being inherited.
      # @return [void]
      def inherited(subclass)
        class_name = subclass.name
        class_name = subclass.to_s if class_name.nil?
        real_class_name = class_name.split("::").last
        @myname = real_class_name.underscore
        agent_list = AgentList.instance
        agent_list.add_agent(
          @myname,
          subclass.name,
        )
      end
    end

    # @param params [Hash] Parameters for initializing the agent.
    # TODO: projectしか使っていないのでハッシュのパラメータはやめる
    def initialize(params = {})
      @project = params[:project]
      @llm_provider = RedmineAiHelper::LlmProvider.get_llm_provider

      @client = @llm_provider.generate_client
      @llm_type = RedmineAiHelper::LlmProvider.type
    end

    # Returns the LLM client.
    def assistant
      return @assistant if @assistant
      tools = available_tool_providers.map { |tool|
        tool.new
      }
      @assistant = RedmineAiHelper::AssistantProvider.get_assistant(
        llm_type: llm_type,
        llm: client,
        instructions: system_prompt,
        tools: tools,
      )
      @assistant.llm_provider = llm_provider
      @assistant
    end

    # List all tools provided by this tool provider.
    # if [] is returned, the agent will be able to use all tools.
    def available_tool_providers
      []
    end

    # The role of the agent
    def role
      self.class.to_s.split("::").last.underscore
    end

    # The backstory of the agent
    def backstory
      raise NotImplementedError
    end

    # The content of the system prompt
    # @return [Hash] The system prompt content.
    def system_prompt
      time = Time.now.iso8601
      prompt = load_prompt("base_agent/system_prompt")
      prompt_text = prompt.format(
        role: role,
        backstory: backstory,
        time: time,
      )

      return { role: "system", content: prompt_text }
    end

    # List all tools provided by available tool providers.
    # @return [Array] The list of available tools.
    def available_tools
      tools = []
      available_tool_providers.each do |provider|
        tools << provider.function_schemas.to_openai_format
      end
      tools
    end

    # Chat with the assistant.
    # @param messages [Array] The messages to be sent to the assistant.
    # @param option [Hash] Additional options for the chat.
    # @param callback [Proc] A callback function to be called with each chunk of the response.
    # @return [String] The response from the assistant.
    def chat(messages, option = {}, callback = nil)
      chat_params = llm_provider.create_chat_param(system_prompt, messages)
      answer = ""
      response = client.chat(chat_params) do |chunk|
        content = llm_provider.chunk_converter(chunk) rescue nil
        if callback
          callback.call(content)
        end
        answer += content if content
      end
      answer = response.chat_completion if llm_type == RedmineAiHelper::LlmProvider::LLM_GEMINI
      answer
    end

    # Perform a task using the assistant.
    # @param messages [Array] The messages to be sent to the assistant.
    # @param option [Hash] Additional options for the task.
    # @param callback [Proc] A callback function to be called with each chunk of the response.
    # @return [Array] The result of the task.
    def perform_task(messages, option = {}, callback = nil)
      new_messages = messages.dup
      task = new_messages.pop
      return dispatch(task, new_messages)
    end

    # dispatch the tool
    # @param task [String] The task to be dispatched.
    # @param messages [Array] The messages to be sent to the assistant.
    # @param pre_tasks [Array] The pre-tasks to be sent to the assistant. TODO: 使っていない
    # @param previous_error [String] The previous error message (optional).
    # @return [TaskResponse] The response from the task.
    def dispatch(task, messages, previous_error = nil)
      begin
        assistant.add_message(role: "assistant", content: "previous error: #{previous_error}") if previous_error
        response = assistant.add_message_and_run!(content: task)

        answer = response.last.content
        res = TaskResponse.create_success answer
        res
      rescue => e
        ai_helper_logger.error "error: #{e.full_message}"
        TaskResponse.create_error e.message
      end
    end

    def load_prompt(name)
      RedmineAiHelper::Util::PromptLoader.load_template(name)
    end

    class TaskResponse < RedmineAiHelper::ToolResponse
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
      @agents.delete_if { |a| a[:name] == name }
      @agents << agent
    end

    def get_agent_instance(name, option = {})
      agent_name = name
      agent_name = "leader_agent" if name == "leader"
      agent = find_agent(agent_name)
      raise "Agent not found: #{agent_name}" unless agent
      agent_class = Object.const_get(agent[:class])
      agent_class.new(option)
    end

    def list_agents
      @agents.map { |a|
        agent = Object.const_get(a[:class]).new
        {
          agent_name: a[:name],
          backstory: agent.backstory,
        }
      }
    end

    def find_agent(name)
      @agents.find { |a| a[:name] == name }
    end
  end
end
