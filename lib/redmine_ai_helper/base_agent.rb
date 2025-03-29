require "redmine_ai_helper/logger"

module RedmineAiHelper
  class BaseAgent
    attr_accessor :model
    include RedmineAiHelper::Logger

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

    def initialize(params = {})
      params[:access_token] ||= Setting.plugin_redmine_ai_helper["access_token"]
      params[:uri_base] ||= Setting.plugin_redmine_ai_helper["uri_base"]
      params[:organization_id] ||= Setting.plugin_redmine_ai_helper["organization_id"]
      @model ||= Setting.plugin_redmine_ai_helper["model"]
      @project = params[:project]
      llm_options = {
        uri_base: params[:uri_base],
      }

      @client = Langchain::LLM::OpenAI.new(
        api_key: params[:access_token],
        llm_options: llm_options,
        default_options: {
          chat_completion_mode_name: @modle,
        },
      )
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
      content = <<~EOS
        あなたは RedmineAIHelper プラグインのエージェントです。
        RedmineAIHelper プラグインは、Redmine のユーザーにRedmine の機能やプロジェクト、チケットなどに関する問い合わせに答えます。

        あなた方エージェントのチームが作成した最終回答はユーザーのRedmineサイト内に表示さます。もし回答の中にRedmine内のページへのリンクが含まれる場合、そのURLにはホスト名は含めず、"/"から始まるパスのみを記載してください。

        ** あなたのロールは #{role} です。これはとても重要です。忘れないでください。**
        RedmineAIHelperには複数のロールのエージェントが存在します。
        あなたは他のエージェントと協力して、RedmineAIHelper のユーザーにサービスを提供します。
        あなたへの指示は <<leader>> ロールのエージェントから受け取ります。
        ----
        現在の時刻は#{Time.now.iso8601}です。
        ----
        あなたのバックストーリーは以下の通りです。
        #{backstory}

      EOS

      return { role: "system", content: content }
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
      @client.chat(messages: messages) do |chunk|
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
        answer = result.value
      end
      pre_tasks
    end

    def decompose_task(messages)
      prompt = <<~EOS
        leader から与えられたタスクを解決するために必要なステップに分解してください。
        ステップの分解には以下のJSONに示すtoolsのリストを参考にしてください。一つ一つのステップは文章で作成します。
        各ステップでは、前のステップの実行で得られた結果をどのように利用するかを考慮してください。
        それらをまとめて「ステップの分解のJSONのスキーマ」にマッチするJSONを作成してください。

        ２つ以上のステップに分解がする必要がない場合には元のタスクをそのまま一つのステップとして記述してください。
        タスクを解決するためにツールの実行が不要な場合にはステップを分解する必要はありません。

        ** ステップの目的が情報の収集や取得の場合には、情報を作成したり更新したりするtoolを絶対に選ばないでください。 **

        ** 回答にはJSON以外を含めないでください。解説等は不要です。 **
        ----
        ステップの分解のJSONのスキーマ:
        {
          "type": "object",
          "properties": {
            "steps": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "name": {
                    "type": "string",
                    "description": "ステップの名前"
                  },
                  "step": {
                    "type": "string",
                    "description": "ステップの内容"
                  },
                  "tool": {
                    "type": "object",
                    "properties": {
                      "provider": {
                        "type": "string",
                        "description": "ツールのプロバイダー"
                      },
                      "tool_name": {
                        "type": "string",
                        "description": "ツールの名前"
                      },
                    },
                    "description": "ツールの情報"
                  }
                  required: ["name", "step"]
                }
              }
            }
          }
        }
        ----
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
        ----
        tools:
        #{available_tools}
        ("\n")}
      EOS

      newmessages = messages.dup
      newmessages << { role: "user", content: prompt }

      json = chat(newmessages)

      RedmineAiHelper::Util::JsonExtractor.extract(json)
    end

    # dispatch the tool
    def dispatch(task, messages, pre_tasks = [], previous_error = nil)
      begin
        response = assistant.add_message_and_run!(content: task)

        res = TaskResponse.create_success response
        res
      rescue => e
        ai_helper_logger.error "error: #{e.full_message}"
        TaskResponse.create_error e.message
      end
    end

    # select the toos to solve the task
    def select_tool(task, messages, pre_tasks = [], previous_error = nil)
      tools = ToolProvider.list_tools

      previous_error_string = ""
      if previous_error
        previous_error_string = "\n----\n前回のツール実行でエラーが発生しました。今回はそのリトライです。前回のエラー内容は以下の通りです。このエラーが再度発生しないようにツールの選択とパラメータの作成してください。\n#{previous_error}"
      end

      pre_tasks_string = ""
      if pre_tasks.length > 0
        pre_tasks_string = <<~EOS
          このタスクを解決するためにこれまでに実施したステップは以下の通りです。これらの結果を踏まえて、次のステップで使用するツールを選んでください。
          事前のステップ:
          #{JSON.pretty_generate(pre_tasks)}
        EOS
      end

      prompt = <<~EOS
        「#{task}」というタスクを解決するのに最適なツールを以下のツールのリストのJSONの中から選択してください。ツールのリストに無いものは含めないでください。
        #{pre_tasks_string}

        ** ツールは一つだけ選択できます。絶対に2つ以上ツールを選択しないでください。 **
        選択には過去の会話履歴も参考にしてください。
        また、そのツールに渡すのに必要な引数も作成してください。

        #{previous_error_string}

        回答は以下の形式のJSONで作成してください。最適なツールがない場合は、tool:にnullを設定してください。

        JSONの例:
        {
          tool:
            {
              "provider": "issue_tool_provider",
              "tool": "read_issue",
              "arguments": {  "id": 1 }
            }
        }
        ** 回答にはJSON以外を含めないでください。解説等は不要です。 **
        ----
        ツールのリスト
        #{tools}

      EOS

      newmessages = messages.dup
      newmessages << { role: "user", content: prompt }

      json = chat(newmessages)

      ai_helper_logger.debug "json: #{json}"
      RedmineAiHelper::Util::JsonExtractor.extract(json)
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

    def all_agents
      @agents
    end

    def get_agent_instance(name, option = {})
      agent = find_agent(name)
      return nil unless agent
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
