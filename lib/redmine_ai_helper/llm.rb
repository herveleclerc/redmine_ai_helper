require "redmine_ai_helper/agent"
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
      goal = task
      begin
        result = execute_task(goal, task, conversation)
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

    def execute_task(goal, task, conversation, pre_tasks = [], depth = 0, pre_error = nil)
      answer = ""
      tasks = decompose_task(goal, task, conversation, pre_tasks, pre_error)
      result = {
        status: "error",
        error: "Failed to decompose the task",
      }
      put_log "tasks: #{tasks}"
      if tasks.length > 1 and depth < 4
        depth += 1
        tasks.each do |task|
          max_retry = 3
          previous_error = nil
          max_retry.times do |i|
            result = execute_task(goal, task, conversation, pre_tasks, depth, previous_error)
            break if result[:status] == "success"
            if i == max_retry - 1
              return result
            end
            previous_error = result[:error]
          end
          pre_task = {
            "name": task["name"],
            "step": task["step"],
            "result": result[:answer],
          }
          pre_tasks << pre_task
        end
        answer = merge_results(goal, task, conversation, pre_tasks)
        result = {
          status: "success",
          answer: answer,
        }
      else
        result = dispatch(goal, task, conversation, pre_tasks)
      end
      result
    end

    def merge_results(goal, task, conversation, pre_tasks)
      messages = []
      messages << {
        role: "system",
        content: system_prompt(conversation),
      }
      goal_string = ""
      if goal != task
        goal_string = "なお、このタスクが最終的に解決したいゴールは「#{goal}」です。"
      end
      pre_task_string = ""

      prompt = <<-EOS
「 #{task}」というタスクを解決するために今までに実施したステップは以下の通りです。これらの結果の内容をまとめて、最終回答を作成してください。
#{goal_string}
回答の作成には過去の会話履歴も参考にしてください。
----
事前のステップ:
#{pre_tasks.map { |pre_task| "----\n#{pre_task["name"]}: #{pre_task["step"]}\n#{pre_task["result"]}" }.join("\n")}
----
過去の会話履歴:
#{conversation.messages.map { |message| "----\n#{message.role}: #{message.content}" }.join("\n")}

EOS
    end

    # decompose the task
    # @param [String] goal
    # @param [String] task
    # @param [Conversation] conversation
    # @param [Array] pre_tasks
    # @param [String] pre_error
    def decompose_task(goal, task, conversation, pre_tasks = [], pre_error = nil)
      tools = Agent.listTools
      messages = []
      messages << {
        role: "system",
        content: system_prompt(conversation),
      }
      goal_string = ""
      if goal != task
        goal_string = "なお、このタスクが最終的に解決したいゴールは「#{goal}」です。"
      end
      pre_error_string = ""
      if pre_error
        pre_error_string = "\n----\n前回のタスク実行でエラーが発生しました。今回はそのリトライです。前回のエラー内容は以下の通りです。このエラーが再度発生しないようにタスクを作成してください。\n#{pre_error}"
      end
      pre_task_string = ""
      if pre_tasks.length > 0
        pre_task_string = <<-EOS
---
「#{goal}」を解決するためにこれまでに実施したステップは以下の通りです。これらの結果を踏まえて、次のステップを考えてください。
事前のステップ:
#{pre_tasks.map { |pre_task| "----\n#{pre_task["name"]}: #{pre_task["step"]}\n#{pre_task["result"]}" }.join("\n")}
---
EOS
      end

      prompt = <<-EOS
「#{task}」というタスクを解決するために必要なステップに分解してください。#{goal_string}
ステップの分解には以下のJSONに示すtoolsのリストを参考にしてください。一つ一つのステップは文章で作成します。それらをまとめてJSONを作成してください。２つ以上のステップに分解ができない場合には元のタスクをそのまま一つのステップとして記述してください。
#{pre_task_string}
#{pre_error_string}
ステップの作成には過去の会話履歴も参考にしてください。
** 回答にはJSON以外を含めないでください。解説等は不要です。 **
----
JSONの例:
{
  "steps": [
    {
          "name": "step1",
          "step": "プロジェクトの一覧を取得する",
        },
    {
          "name": "step2",
          "step": "個々のプロジェクトの詳細情報を取得する",
        },
  ],
}
----
tools:
#{tools}
----
過去の会話履歴:
#{conversation.messages.map { |message| "----\n#{message.role}: #{message.content}" }.join("\n")}
      EOS
      messages << { role: "user", content: prompt }
      put_log "message: #{messages.last[:content]}"
      response = @client.chat(
        parameters: {
          model: @model,
          messages: messages,
        },
      )
      json = response["choices"][0]["message"]["content"]
      put_log "json: #{json}"
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

      answer
    end

    # dispatch the tool
    def dispatch(goal, task, conversation, pre_tasks = [])
      response = select_tools(goal, task, conversation)
      tools = response["tools"]
      return simple_llm_chat(conversation) if tools.empty?

      begin
        results = {
          results: [],
        }
        tools.each do |tool|
          agent = Agent.new(@client)
          put_log "tool: #{tool}"
          result = agent.callTool(name: tool["name"], arguments: tool["arguments"])
          put_log "result: #{result}"
          results[:results] << result
        end

        json_str = results.to_json
        messages = []
        messages << {
          role: "system",
          content: system_prompt(conversation),
        }
        prompt = <<-EOS
ツールの実行結果は以下のJSONになります。ユーザーに回答する文章を作成してください。回答は簡潔に要約してください。
箇条書きで回答可能であれば、箇条書きで回答を作成してください。
また、過去の会話履歴も参考にしてください。
----
JSON:
#{json_str}
----
過去の会話履歴:
#{conversation.messages.map { |message| "----\n#{message.role}: #{message.content}" }.join("\n")}

        EOS
        messages << { role: "user", content: prompt }
        put_log "message: #{messages.last[:content]}"
        response = @client.chat(
          parameters: {
            model: @model,
            messages: messages,
          },
        )
        answer = response["choices"][0]["message"]["content"]
        put_log "answer: #{answer}"
        result = {
          status: "success",
          answer: answer,
        }
        result
      rescue => e
        result = {
          status: "error",
          error: e.full_message,
        }
        result
      end
    end

    # select the toos to solve the task
    def select_tools(goal, task, conversation)
      tools = Agent.listTools
      messages = []
      messages << {
        role: "system",
        content: system_prompt(conversation),
      }
      conversation_history = ""
      conversation.messages.each do |message|
        conversation_history += "----\n#{message.role}: #{message.content}\n"
      end

      prompt = <<-EOS
「#{task}」を解決するのに最適なツールを以下のツールのリストのJSONの中から選択してください。
ツールは複数選択できます。選択には過去の会話履歴も参考にしてください。
また、そのツールに渡すのに必要な引数も作成してください。

回答は以下の形式のJSONで作成してください。最適なツールがない場合は、toolsが空の配列のJSONを返してください。

JSONの例:
{
  tools: [
    {
      "name": "read_issue",
      "arguments": {  "id": 1 }
    },
    {
      "name": "list_issues",
      "arguments": {  "project_id": 1 }
    },
  ]
}
** 回答にはJSON以外を含めないでください。解説等は不要です。 **
----
ツールのリスト
#{tools}
----
過去の会話履歴:
#{conversation_history}
      EOS
      messages << { role: "user", content: prompt }
      put_log "message: #{messages.last[:content]}"
      response = @client.chat(
        parameters: {
          model: @model,
          messages: messages,
        },
      )
      json = response["choices"][0]["message"]["content"]
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
      }
      prompt = <<-EOS
あなたはRedmine AI Helperプラグインです。Redmineにインストールされており、Redmineのユーザーからの問い合わせに答えます。
問い合わせの内容はRedmineの機能やプロジェクト、チケットなどこのRedmineに登録されているデータに関するものが主になります。
特に、現在表示しているプロジェクトやページの情報についての問い合わせに答えます。
あなたがこのRedmineのサイト内のページを示すURLへのリンクを回答する際には、URLにはホスト名やポート番号は含めず、パスのみを含めてください。(例: /projects/redmine_ai_helper/issues/1)

あなたは日本語、英語、中国語などいろいろな国の言語を話すことができますが、あなたが回答する際の言語は、特にユーザーからの指定が無い限りは#{I18n.t(:general_lang_name)}で話します。

以下はあなたの参考知識です。
----
参考情報：
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

    def put_log(message)
      puts "####################################################"
      puts message
      puts "####################################################"
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
