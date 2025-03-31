require "langchain"
require "redmine_ai_helper/logger"
Langchain.logger.level = Logger::ERROR

module RedmineAiHelper
  class BaseAgent
    attr_accessor :model
    include RedmineAiHelper::Logger

    class << self

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

    def initialize(params = {})
      @project = params[:project]

      @client = RedmineAiHelper::LlmProvider.get_llm
    end

    def assistant
      return @assistant if @assistant
      tools = available_tool_providers.map { |tool|
        tool.new
      }
      @assistant = Langchain::Assistant.new(
        llm: @client,
        instructions: system_prompt,
        tools: tools,
      )
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
    def available_tools
      tools = []
      available_tool_providers.each do |provider|
        tools << provider.function_schemas.to_openai_format
      end
      tools
    end

    def chat(messages, option = {}, callback = nil)
      messages_with_systemprompt = [system_prompt] + messages
      messages_with_systemprompt.each do |message|
        # message[:role] が system でも asssistant でも ユーザーでもない場合はエラー
        unless %w(system assistant user).include?(message[:role])
          raise "Invalid role: #{message[:role]}, message: #{message[:content]}"
        end
      end
      answer = ""
      @client.chat(messages: messages_with_systemprompt) do |chunk|
        content = chunk.dig("delta", "content") rescue nil
        if callback
          callback.call(content)
        end
        answer += content if content
      end
      answer
    end

    def perform_task(messages, option = {}, callback = nil)
      tasks = decompose_task(messages)
      assistant.clear_messages!
      assistant.add_message(role: "system", content: system_prompt[:content])
      messages.each do |message|
        assistant.add_message(role: message[:role], content: message[:content])
      end
      pre_tasks = []
      tasks["steps"].each do |new_task|
        ai_helper_logger.debug "new_task: #{new_task}"
        result = nil
        previous_error = nil
        max_retry = 3
        max_retry.times do |i|
          result = dispatch(new_task["step"], messages, pre_tasks, previous_error)
          break if result.is_success?

          previous_error = result.error
          ai_helper_logger.debug "retry: #{i}"
        end
        pre_task = {
          "name": new_task["name"],
          "step": new_task["step"],
          "result": result.value,
        }
        ai_helper_logger.debug "pre_task: #{pre_task}"
        pre_tasks << pre_task
        result.value
      end
      pre_tasks
    end

    def decompose_task(messages)
      json_schema = {
        "type": "object",
        "properties": {
          "steps": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "name": {
                  "type": "string",
                  "description": "ステップの名前",
                },
                "step": {
                  "type": "string",
                  "description": "ステップの内容",
                },
                "tool": {
                  "type": "object",
                  "properties": {
                    "provider": {
                      "type": "string",
                      "description": "ツールのプロバイダー",
                    },
                    "tool_name": {
                      "type": "string",
                      "description": "ツールの名前",
                    },
                  },
                  "description": "ツールの情報",
                },
              },
              "required": ["name", "step"],
            },
          },
        },
      }
      parser = Langchain::OutputParsers::StructuredOutputParser.from_json_schema(json_schema)

      json_examples =<<~EOS
        タスクの例:
        「チケットID 3のチケットのステータスを完了に変更する」
        JSONの例:
        {
          "steps": [
            {
                  "name": "step1",
                  "step": "チケットを更新するために、必要な情報を整理する。",
                  "tool": {
                    "provider": "issue_tool_provider",
                    "tool_name": "capable_issue_properties"
                  }
            },
            {
                  "name": "step2",
                  "step": "前のステップで取得したステータスを使用してチケットを更新する",
                  "tool": {
                    "provider": "issue_tool_provider",
                    "tool_name": "update_issue",
                  }
            }
          ]
        }
      EOS

      prompt = load_prompt("base_agent/decompose_task")
      prompt_text = prompt.format(
        format_instructions: parser.get_format_instructions,
        json_examples: json_examples,
        available_tools: available_tools,
      )

      newmessages = messages.dup
      newmessages << { role: "user", content: prompt_text }
      json = chat(newmessages)
      fix_parser = Langchain::OutputParsers::OutputFixingParser.from_llm(
        llm: @client,
        parser: parser
      )
      fix_parser.parse(json)

    end

    # dispatch the tool
    def dispatch(task, messages, pre_tasks = [], previous_error = nil)
      begin
        assistant.add_message(role: "assistant", content: "previous error: #{previous_error}") if previous_error
        response = assistant.add_message_and_run!(content: task)

        res = TaskResponse.create_success response
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
