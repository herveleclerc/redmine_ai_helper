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
    def chat(conversation)
      messages = conversation.messages.map do |message|
        {
          role: message.role,
          content: message.content,
        }
      end
      tool = select_tool(messages.last, conversation)
      puts "####################"
      p tool
      system_message = {
        role: "system",
        content: system_prompt(conversation),
      }
      messages.prepend(system_message)
      response = @client.chat(
        parameters: {
          model: @model,
          messages: messages,
        },
      )

      AiHelperMessage.new(role: "assistant", content: response["choices"][0]["message"]["content"], conversation: conversation)
    end

    # select the tool to solve the task
    def select_tool(task, conversation)
      tools = Agent.listTools
      messages = []
      messages << {
        role: "system",
        content: system_prompt(conversation),
      }
      conversation_history = ""
      conversation.messages.each do |message|
        conversation_history += "#{message.role}: #{message.content}\n"
      end

      prompt = <<-EOS
#{task}を解決するのに最適なツールを以下のJSONの中から選択してください。選択には過去の会話履歴も参考にしてください。また、そのツールに渡すのに必要な引数も作成してください。
回答は以下の形式のJSONで作成してください。最適なツールがない場合は、空のJSONを返してください。

JSONの例:
{
  "name": "read_issue",
  "arguments": {  "id": 1 }
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
      response = @client.chat(
        parameters: {
          model: @model,
          messages: messages,
        },
      )
      json = response["choices"][0]["message"]["content"]
      JsonExtractor.extract(json)
    end

    # generate system prompt
    def system_prompt(conversation = nil)
      project = conversation.nil? ? nil : conversation.project
      prompt = <<-EOS
あなたはRedmine AI Helperプラグインです。Redmineにインストールされており、Redmineのユーザーからの問い合わせに答えます。
問い合わせの内容はRedmineの機能やプロジェクト、チケットなどこのRedmineに登録されているデータに関するものが主になります。
特に、現在表示しているプロジェクトやページの情報についての問い合わせに答えます。

あなたは日本語、英語、中国語などいろいろな国の言語を話すことができますが、あなたが回答する際の言語は、特にユーザーからの指定が無い限りは#{I18n.t(:general_lang_name)}で話します。

以下はあなたの参考知識です。
----
参考情報：
JSONで定義したこのRedmineのサイト情報は以下になります。
JSONの中のcurrent_projectが現在ユーザーが表示している、このプロジェクトです。

#{site_info_json(project: project)}

      EOS

      prompt
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
          raise "Invalid JSON format: #{e.message}"
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
