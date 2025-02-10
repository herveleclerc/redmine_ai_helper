module RedmineAiHelper
  module Util
    class SystemPrompt
      def initialize(option = {})
        @controller_name = option[:controller_name]
        @action_name = option[:action_name]
        @content_id = option[:content_id]
        @additional_info = option[:additional_info]
        @project = option[:project]
      end

      def prompt(conversation = nil)
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
  #{site_info_json(project: @project)}

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
        case @controller_name
        when "projects"
          page_name = "プロジェクト「#{@project.name}」の情報ページです"
        when "issues"
          case @action_name
          when "show"
            issue = Issue.find(@content_id)
            page_name = "チケット ##{issue.id} の詳細\nユーザが特にIDや名前を指定せずにただ「チケット」といった場合にはこのチケットのことです。"
          when "index"
            page_name = "チケット一覧"
          else
            page_name = "チケットの#{@action_name}ページです"
          end
        when "wiki"
          case @action_name
          when "show"
            page = WikiPage.find(@content_id)
            page_name = "「#{page.title}」というタイトルのWikiページを表示しています。\nユーザが特にタイトルを指定せずにただ「Wikiページ」や「ページ」といった場合にはこのWikiページのことです。"
          end
        when "repositories"
          repo = Repository.find(@content_id)
          case @action_name
          when "show"
            page_name = "リポジトリ「#{repo.name}」の情報ページです。リポジトリのIDは #{repo.id} です。"
          when "entry"
            page_name = "リポジトリのファイル情報のページです。表示しているファイルパスは #{@additional_info["path"]} です。リビジョンは #{@additional_info["rev"]} です。リポジトリは「 #{repo.name}」です。リポジトリのIDは #{repo.id} です。"
          when "diff"
            page_name = "リポジトリ「#{repo.name}」の変更差分ページです。リポジトリのIDは #{repo.id} です。"
            page_name += "リビジョンは #{@additional_info["rev"]} です。" unless @additional_info["rev_to"]
            page_name += "リビジョンは #{@additional_info["rev"]} から #{@additional_info["rev_to"]} です。" if @additional_info["rev_to"]
            page_name += "ファイルパスは #{@additional_info["path"]} です。" if @additional_info["path"]
          when "revision"
            page_name = "リポジトリ「#{repo.name}」のリビジョン情報ページです。リビジョンは #{@additional_info["rev"]} です。リポジトリのIDは #{repo.id} です。"
          else
            page_name = "リポジトリの情報ページです"
          end
        when "boards"
          case @action_name
          when "show"
            board = Board.find(@content_id)
            page_name = "ボード「#{board.name}」の情報ページです。"
          when "index"
            page_name = "ボード一覧"
          else
            page_name = "ボードの#{@action_name}ページです"
          end
        else
          page_name = "{@controller_name}の{@action_name}ページです"
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
    end
  end
end
