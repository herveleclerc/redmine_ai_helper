require "redmine_ai_helper/agent"
require "redmine_ai_helper/agent_response"
require "redmine_ai_helper/logger"
require "redmine_ai_helper/util/system_prompt"
require "redmine_ai_helper/util/json_extractor"
require "openai"
require "json"

module RedmineAiHelper
  class Llm
    include RedmineAiHelper::Logger
    attr_accessor :model

    # initialize the client
    # @param [Hash] params
    # @option params [String] :access_token
    # @option params [String] :uri_base
    # @option params [String] :organization_id
    def initialize(params = {})
      params[:access_token] ||= Setting.plugin_redmine_ai_helper["access_token"]
      params[:uri_base] ||= Setting.plugin_redmine_ai_helper["uri_base"]
      params[:organization_id] ||= Setting.plugin_redmine_ai_helper["organization_id"]
      @model ||= Setting.plugin_redmine_ai_helper["model"]

      @client = OpenAI::Client.new(params)
      @system_prompt = RedmineAiHelper::Util::SystemPrompt.new
      ai_helper_logger = ai_helper_logger
    end

    # chat with the AI
    def chat(conversation, option = {})
      @system_prompt = RedmineAiHelper::Util::SystemPrompt.new(option)
      task = conversation.messages.last.content
      ai_helper_logger.info "#### ai_helper: chat start ####"
      ai_helper_logger.info "user:#{User.current}, task: #{task}, option: #{option}"
      begin
        result = execute_task(task, conversation)
        if result[:status] == "success"
          answer = result[:answer]
        else
          answer = result[:error]
        end
      rescue => e
        ai_helper_logger.error "error: #{e.full_message}"
        answer = e.message
      end
      ai_helper_logger.info "answer: #{answer}"
      AiHelperMessage.new(role: "assistant", content: answer, conversation: conversation)
    end

    def execute_task(task, conversation)
      answer = ""
      result = {
        status: "error",
        error: "Failed to decompose the task",
      }
      pre_tasks = []
      tasks = decompose_task(task, conversation)
      ai_helper_logger.info "tasks: #{tasks}"

      tasks["steps"].each do |new_task|
        ai_helper_logger.debug "new_task: #{new_task}"
        previous_error = nil
        max_retry = 3
        max_retry.times do |i|
          result = dispatch(new_task["step"], conversation, pre_tasks, previous_error)
          break if result.is_success?

          previous_error = result.error
          ai_helper_logger.debug "retry: #{i}"
        end
        pre_task = {
          "name": new_task["name"],
          "step": new_task["step"],
          "result": result.value,
        }
        ai_helper_logger.info "pre_task: #{pre_task}"
        pre_tasks << pre_task
        answer = result.value
      end

      answer = merge_results(task, conversation, pre_tasks) if pre_tasks.length
      result = {
        status: "success",
        answer: answer,
      }
      ai_helper_logger.info "result: #{result}"
      result
    end

    def merge_results(task, conversation, pre_tasks)
      prompt = <<-EOS
「 #{task}」というタスクを解決するために今までに実施したステップは以下の通りです。これらの結果の内容を踏まえて、タスクに対する最終回答を作成してください。

最終回答はタスクに対する自然な会話となる文章です。文章は要点をまとめてなるべく箇条書きにしてください。
回答にURLを含める際には、ユーザーがアクセスしやすいようにリンクを生成してください。
** 最終回答には会話の文章のみ含めてください。解説は不要です。 **

回答の作成には過去の会話履歴も参考にしてください。
----
事前のステップ:
#{pre_tasks}

EOS
      json = chat_wrapper(prompt, conversation)
      json
    end

    # decompose the task
    # @param [Conversation] conversation
    # @param [Array] pre_tasks
    # @param [String] pre_error
    def decompose_task(task, conversation, pre_tasks = [], pre_error = nil)
      tools = Agent.list_tools

      pre_error_string = ""
      if pre_error
        pre_error_string = "\n----\n前回のタスク実行でエラーが発生しました。今回はそのリトライです。前回のエラー内容は以下の通りです。このエラーが再度発生しないようにタスクを作成してください。\n#{pre_error}"
      end
      pre_task_string = ""
      if pre_tasks.length > 0
        pre_task_string = <<-EOS
---
「#{task}」を解決するためにこれまでに実施したステップは以下の通りです。これらの結果を踏まえて、次のステップを考えてください。
事前のステップ:
#{pre_tasks.map { |pre_task| "----\n#{pre_task["name"]}: #{pre_task["step"]}\n#{pre_task["result"]}" }.join("\n")}
---
EOS
      end

      prompt = <<-EOS
「#{task}」というタスクを解決するために必要なステップに分解してください。
ステップの分解には以下のJSONに示すtoolsのリストを参考にしてください。一つ一つのステップは文章で作成します。
各ステップでは、前のステップの実行で得られた結果をどのように利用するかを考慮してください。
それらをまとめて「ステップの分解のJSONのスキーマ」にマッチするJSONを作成してください。

２つ以上のステップに分解がする必要がない場合には元のタスクをそのまま一つのステップとして記述してください。
タスクを解決するためにツールの実行が不要な場合にはステップを分解する必要はありません。

#{pre_task_string}
#{pre_error_string}

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
          }
          required: ["name", "step"]
        }
      }
    }
  }
}
----
タスクの例:
「トラッカーがサポートのチケットを探す」
JSONの例:
{
  "steps": [
    {
          "name": "step1",
          "step": "名前がサポートのトラッカーのIDを取得する",
        },
    {
          "name": "step2",
          "step": "前のステップで取得したトラッカーのIDを使用して、そのトラッカーのチケットを探す",
        },
  ],
}
----
tools:
#{tools}
("\n")}
      EOS

      json = chat_wrapper(prompt, conversation)

      RedmineAiHelper::Util::JsonExtractor.extract(json)
    end

    def simple_llm_chat(conversation)
      messages = conversation.messages.map do |message|
        {
          role: message.role,
          content: message.content,
        }
      end
      system_message = {
        role: "system",
        content: @system_prompt.prompt(conversation),
      }
      messages.prepend(system_message)
      ai_helper_logger.info "message: #{messages.last[:content]}"
      response = @client.chat(
        parameters: {
          model: @model,
          messages: messages,
        },
      )

      answer = response["choices"][0]["message"]["content"]
      ai_helper_logger.debug "answer: #{answer}"

      return TaskResponse.create_success answer
    end

    # dispatch the tool
    def dispatch(task, conversation, pre_tasks = [], previous_error = nil)
      begin
        response = select_tool(task, conversation, pre_tasks, previous_error)
        tool = response["tool"]
        ai_helper_logger.info "tool: #{tool}"
        return simple_llm_chat(conversation) if tool.blank?

        agent = Agent.new(@client, @model)
        result = agent.call_tool(agent_name: tool["agent"], name: tool["tool"], arguments: tool["arguments"])
        ai_helper_logger.info "result: #{result}"
        if result.is_error?
          ai_helper_logger.error "error!!!!!!!!!!!!: #{result}"
          return result
        end

        res = TaskResponse.create_success result.value
        res
      rescue => e
        ai_helper_logger.error "error: #{e.full_message}"
        TaskResponse.create_error e.message
      end
    end

    # select the toos to solve the task
    def select_tool(task, conversation, pre_tasks = [], previous_error = nil)
      tools = Agent.list_tools

      previous_error_string = ""
      if previous_error
        previous_error_string = "\n----\n前回のツール実行でエラーが発生しました。今回はそのリトライです。前回のエラー内容は以下の通りです。このエラーが再度発生しないようにツールの選択とパラメータの作成してください。\n#{previous_error}"
      end

      pre_tasks_string = ""
      if pre_tasks.length > 0
        pre_tasks_string = <<-EOS
このタスクを解決するためにこれまでに実施したステップは以下の通りです。これらの結果を踏まえて、次のステップで使用するツールを選んでください。
事前のステップ:
#{JSON.pretty_generate(pre_tasks)}
        EOS
      end

      prompt = <<-EOS
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
      "agent": "issue_agent",
      "tool": "read_issue",
      "arguments": {  "id": 1 }
    }
}
** 回答にはJSON以外を含めないでください。解説等は不要です。 **
----
ツールのリスト
#{tools}

      EOS

      json = chat_wrapper(prompt, conversation)

      ai_helper_logger.info "json: #{json}"
      RedmineAiHelper::Util::JsonExtractor.extract(json)
    end

    private

    def chat_wrapper(new_message, conversation)
      ai_helper_logger.debug "new_message: #{new_message}"
      location = caller_locations(1, 1)[0]
      ai_helper_logger.debug "caller: #{location.base_label}::#{location.path}:#{location.lineno}:#{location.base_label}"
      messages = conversation.messages.map do |message|
        {
          role: message.role,
          content: message.content,
        }
      end
      system_message = {
        role: "system",
        content: @system_prompt.prompt(conversation),
      }
      messages.prepend(system_message)
      messages << {
        role: "user",
        content: new_message,
      }
      ai_helper_logger.debug "message: #{messages.last[:content]}"
      response = @client.chat(
        parameters: {
          model: @model,
          messages: messages,
        },
      )

      answer = response["choices"][0]["message"]["content"]
      ai_helper_logger.debug "answer: #{answer}"
      answer
    end

    class TaskResponse < RedmineAiHelper::AgentResponse
    end
  end
end
