require "redmine_ai_helper/agent"
require "openai"
require "json"

module RedmineAiHelper
  class Llm
    attr_accessor :model

    def initialize(params = {})
      params[:access_token] ||= Setting.plugin_redmine_ai_helper["access_token"]
      params[:uri_base] ||= Setting.plugin_redmine_ai_helper["uri_base"]
      params[:organization_id] ||= Setting.plugin_redmine_ai_helper["organization_id"]
      @model ||= Setting.plugin_redmine_ai_helper["model"]

      @client = OpenAI::Client.new(params)
    end

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

    # conversationの内容から、taskを解決するのに適切なツールを選択する
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
      return response["choices"][0]["message"]["content"]
    end

    def system_prompt(conversation = nil)
      project = conversation.nil? ? nil : conversation.project
      prompt = <<-EOS
あなたはRedmine AI Helperプラグインです。Redmineにインストールされており、Redmineのユーザーからの問い合わせに答えます。
問い合わせの内容はRedmineの機能やプロジェクト、チケットなどこのRedmineに登録されているデータに関するものが主になります。
特に、現在表示しているプロジェクトやページの情報についての問い合わせに答えます。

あなたは日本語、英語、中国語などいろいろな国の言語を話すことができますが、あなたが回答する際の言語は、特にユーザーからの指定が無い限りは#{I18n.t(:general_lang_name)}で話します。

以下はあなたの参考知識です。
----
JSONで定義したこのRedmineの情報は以下になります。
current_projectが現在ユーザーが表示中のプロジェクトです。

#{site_info_json(project: project)}
----
Redmineの一般的な説明は以下になります。
--
Redmineは、オープンソースのプロジェクト管理ツールです。Ruby on Railsで開発されており、以下のような特徴があります。
プロジェクト管理の主要機能：
チケット（課題）管理：タスクや不具合などをチケットとして登録・追跡できます。優先度、担当者、期限などを設定可能です。
ガントチャート：プロジェクトのスケジュール管理をビジュアル的に行えます。タスクの依存関係や進捗状況を確認できます。
カレンダー：締め切りやマイルストーンをカレンダー形式で表示できます。
Wiki：プロジェクトのドキュメント作成・共有が可能です。Markdownなどの記法に対応しています。
バージョン管理システムとの連携：GitやSVNなどのバージョン管理システムと連携でき、ソースコードの変更履歴とチケットを関連付けられます。
カスタマイズ性：
プラグイン機能により、機能を追加・拡張できます。
ワークフローやチケットのフィールドをカスタマイズ可能です。
多言語対応しており、日本語を含む様々な言語で利用できます。
セキュリティ：
ユーザー管理とロール（役割）ベースのアクセス制御を提供します。
プロジェクトごとに権限を細かく設定できます。
多くの企業や組織で採用されており、特に以下のような場面で活用されています：
・ソフトウェア開発プロジェクトの管理
・社内システムの課題管理
・部門横断的なタスク管理
・ドキュメント共有とナレッジ管理
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
  end
end
