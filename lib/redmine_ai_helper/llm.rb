require "redmine_ai_helper/agent"
require "redmine_ai_helper/agent_response"
require "openai"
require "json"

module RedmineAiHelper
  class Llm
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
    end

    # chat with the AI
    def chat(conversation, option = {})
      @controller_name = option[:controller_name]
      @action_name = option[:action_name]
      @content_id = option[:content_id]
      task = conversation.messages.last.content
      put_log "New message arrived!!!!!!!!!!"
      put_log "task: #{task}"
      begin
        result = execute_task(task, conversation)
        if result[:status] == "success"
          answer = result[:answer]
        else
          answer = result[:error]
        end
      rescue => e
        put_log "error: #{e.full_message}"
        answer = e.message
      end

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
      put_log "tasks:", tasks

      tasks["steps"].each do |new_task|
        put_log "new_task: #{new_task}"
        previous_error = nil
        max_retry = 3
        max_retry.times do |i|
          result = dispatch(new_task["step"], conversation, pre_tasks, previous_error)
          break if result.is_success?

          previous_error = result.error
          put_log "retry: #{i}"
        end
        pre_task = {
          "name": new_task["name"],
          "step": new_task["step"],
          "result": result.value,
        }
        put_log "pre_task: #{pre_task}"
        pre_tasks << pre_task
        answer = result.value
      end

      answer = merge_results(task, conversation, pre_tasks) if pre_tasks.length
      result = {
        status: "success",
        answer: answer,
      }
      put_log "result: #{result}"
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
それらをまとめてJSONを作成してください。

２つ以上のステップに分解がする必要がない場合には元のタスクをそのまま一つのステップとして記述してください。
タスクを解決するためにツールの実行が不要な場合にはステップを分解する必要はありません。

#{pre_task_string}
#{pre_error_string}

** 回答にはJSON以外を含めないでください。解説等は不要です。 **
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

      JsonExtractor.extract(json)
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
        content: system_prompt(conversation),
      }
      messages.prepend(system_message)
      put_log "message: #{messages.last[:content]}"
      response = @client.chat(
        parameters: {
          model: @model,
          messages: messages,
        },
      )

      answer = response["choices"][0]["message"]["content"]
      put_log "answer: #{answer}"

      return TaskResponse.create_success answer
    end

    # dispatch the tool
    def dispatch(task, conversation, pre_tasks = [], previous_error = nil)
      response = select_tool(task, conversation, pre_tasks, previous_error)
      tool = response["tool"]
      return simple_llm_chat(conversation) if tool.blank?

      begin
        agent = Agent.new(@client, @model)
        put_log "tool: #{tool}"
        result = agent.call_tool(agent_name: tool["agent"], name: tool["tool"], arguments: tool["arguments"])
        put_log "result: #{result}"
        if result.is_error?
          put_log "error!!!!!!!!!!!!: #{result}"
          return result
        end

        res = TaskResponse.create_success result.value
        put_log "res: #{res}"
        res
      rescue => e
        put_log "error: #{e.full_message}"
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

      put_log "json: #{json}"
      JsonExtractor.extract(json)
    end

    # generate system prompt
    def system_prompt(conversation = nil)
      project = conversation.nil? ? nil : conversation.project
      current_user_info = {
        id: User.current.id,
        name: User.current.name,
        mail: User.current.mail,
        timezone: User.current.time_zone,
      }
      prompt = <<-EOS
あなたはRedmine AI Helperプラグインです。Redmineにインストールされており、Redmineのユーザーからの問い合わせに答えます。
問い合わせの内容はRedmineの機能やプロジェクト、チケットなどこのRedmineに登録されているデータに関するものが主になります。
特に、現在表示しているプロジェクトやページの情報についての問い合わせに答えます。

注意事項:
- あなたがこのRedmineのサイト内のページを示すURLへのリンクを回答する際には、URLにはホスト名やポート番号は含めず、パスのみを含めてください。(例: /projects/redmine_ai_helper/issues/1)
- あなたは日本語、英語、中国語などいろいろな国の言語を話すことができますが、あなたが回答する際の言語は、特にユーザーからの指定が無い限りは#{I18n.t(:general_lang_name)}で話します。
- ユーザーが「私のチケット」といった場合には、それは「私が作成したチケット」ではなく、「私が担当するチケット」を指します。
- ユーザーへの回答は要点をまとめてなるべく箇条書きにする様心がけてください。

以下はあなたの参考知識です。
----
参考情報：
現在の時刻は#{Time.now.iso8601}です。ただしユーザと時間について会話する場合は、ユーザのタイムゾーンを考慮してください。ユーザーのタイムゾーンがわからない場合には、ユーザーが話している言語や会話から推測してください。
JSONで定義したこのRedmineのサイト情報は以下になります。
JSONの中のcurrent_projectが現在ユーザーが表示している、このプロジェクトです。ユーザが特にプロジェクトを指定せずにただ「プロジェクト」といった場合にはこのプロジェクトのことです。
#{site_info_json(project: project)}

#{current_page_info_string()}

----
あなたと話しているユーザーは"#{User.current}"です。
ユーザーの情報を以下に示します。
#{current_user_info}
      EOS

      prompt
    end

    def current_page_info_string()
      page_name = nil
      if @controller_name == "issues" && @action_name == "show"
        issue = Issue.find(@content_id)
        page_name = "チケット ##{issue.id} の詳細\nユーザが特にIDや名前を指定せずにただ「チケット」といった場合にはこのチケットのことです。"
      elsif @controller_name == "issues" && @action_name == "index"
        page_name = "チケット一覧"
      end
      return "" if page_name.nil?
      string = <<-EOS
----
現在のユーザが表示しているRedmineのページの情報:
ページ名: #{page_name}
      EOS

      string
    end

    def site_info_json(param = {})
      hash = {
        site: {
          title: Setting.app_title,
          welcome_text: Setting.welcome_text,
        },
      }

      if param[:project]
        project = param[:project]
        hash[:current_project] = {
          id: project.id,
          name: project.name,
          description: project.description,
          identifier: project.identifier,
          created_on: project.created_on,

        }
      end

      JSON.pretty_generate(hash)
    end

    private

    def chat_wrapper(new_message, conversation)
      put_log "new_message: #{new_message}"
      location = caller_locations(1, 1)[0]
      put_log "caller: #{location.base_label}::#{location.path}:#{location.lineno}:#{location.base_label}"
      messages = conversation.messages.map do |message|
        {
          role: message.role,
          content: message.content,
        }
      end
      system_message = {
        role: "system",
        content: system_prompt(conversation),
      }
      messages.prepend(system_message)
      messages << {
        role: "user",
        content: new_message,
      }
      put_log "message: #{messages.last[:content]}"
      response = @client.chat(
        parameters: {
          model: @model,
          messages: messages,
        },
      )

      answer = response["choices"][0]["message"]["content"]
      put_log "answer: #{answer}"
      answer
    end

    def put_log(*messages)
      location = caller_locations(1, 1)[0]
      header = "###### #{Time.now.strftime("%Y-%m-%d %H:%M:%S")} #{location.base_label}::#{location.path}:#{location.lineno}:#{location.base_label}"

      message = messages.join(" ")

      #################################"

      puts header
      puts message
      puts "####################################################"
      # 同じメッセージを/tmp/ai_helper.logにも出力
      File.open("#{Rails.root}/log/ai_helper.log", "a") do |f|
        f.puts header
        f.puts message
      end
    end

    class TaskResponse < RedmineAiHelper::AgentResponse
    end

    class JsonExtractor
      def self.extract(input)
        # パターン1: 純粋なJSONテキスト
        # パターン2: Markdownのコードブロックで囲まれたJSON

        # Markdownのコードブロックを処理
        if input.start_with?("```json") && input.end_with?("```")
          # ```json と ``` を削除
          json_str = input.gsub(/^```json\n/, "").gsub(/```$/, "")
        else
          # 純粋なJSONテキストとして扱う
          json_str = input
        end

        # JSONとして解析できるか確認
        begin
          # 文字列からRubyのハッシュに変換
          JSON.parse(json_str)
        rescue JSON::ParserError => e
          raise "Invalid JSON format: #{e.message}: \n###original json\n #{json_str}\n###"
        end
      end

      # 文字列として整形されたJSONを取得するメソッド
      def self.extract_pretty(input)
        hash = extract(input)
        JSON.pretty_generate(hash)
      end
    end
  end
end
