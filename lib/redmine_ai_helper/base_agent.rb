require "redmine_ai_helper/tool_provider"
require "openai"

module RedmineAiHelper
  class BaseAgent
    attr_accessor :model

    class << self
      def myname
        @myname
      end

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

    def initialize(room_id, params = {})
      @room_id = room_id
      params[:access_token] ||= Setting.plugin_redmine_ai_helper["access_token"]
      params[:uri_base] ||= Setting.plugin_redmine_ai_helper["uri_base"]
      params[:organization_id] ||= Setting.plugin_redmine_ai_helper["organization_id"]
      @model ||= Setting.plugin_redmine_ai_helper["model"]

      @client = OpenAI::Client.new(params)
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
      content = <<~EOS
        あなたは RedmineAIHelper プラグインのエージェントです。
        RedmineAIHelper プラグインは、Redmine のユーザーにRedmine の機能やプロジェクト、チケットなどに関する問い合わせに答えます。
        ** あなたのロールは #{role} です。これはとても重要です。忘れないでください。**
        RedmineAIHelperには複数のロールのエージェントが存在します。
        あなたは他のエージェントと協力して、RedmineAIHelper のユーザーにサービスを提供します。
        あなたへの指示は <<leader>> ロールのエージェントから受け取ります。
        ----
        あなたのバックストーリーは以下の通りです。
        #{backstory}
              EOS

      return { role: "system", content: content }
    end

    # List all tools provided by available tool providers.
    def available_tools
      tools = ToolProvider.list_tools
      tools[:providers] = tools[:providers].filter { |provider| available_tool_providers.include?(provider[:name]) } unless available_tool_providers.empty?
      tools
    end

    def chat(messages, option = {}, callback = nil)
      messages_with_systemprompt = [system_prompt] + messages
      answer = ""
      @client.chat(
        parameters: {
          model: @model,
          messages: messages_with_systemprompt,
          stream: proc do |chunk, bytesize|
            content = chunk.dig("choices", 0, "delta", "content")
            if callback
              callback.call(content)
            end
            answer += content if content
          end,
        },
      )
      answer
    end

    def perform_task(messages, option = {}, callback = nil)
      chat(messages, option, callback)
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

    def all_agents
      @agents
    end

    def find_agent(name)
      @agents.find { |a| a[:name] == name }
    end
  end
end
