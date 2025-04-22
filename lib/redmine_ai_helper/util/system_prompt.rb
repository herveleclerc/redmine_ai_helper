# RedmineAIHelper
module RedmineAiHelper
  module Util
    # A class that generates a system prompt for the Leader Agent.
    # Generates a prompt that includes information about the page the user is currently viewing.
    class SystemPrompt
      # Constructor
      # @param option [Hash] Includes project information, user information, page information, etc.
      def initialize(option = {})
        @controller_name = option[:controller_name]
        @action_name = option[:action_name]
        @content_id = option[:content_id]
        @additional_info = option[:additional_info]
        @project = option[:project]
      end

      # Generates a system prompt for the Leader Agent.
      # @param conversation [Object] The conversation object (optional). TODO: 使用していない
      def prompt(conversation = nil)
        current_user_info = {
          id: User.current.id,
          name: User.current.name,
          mail: User.current.mail,
          timezone: User.current.time_zone,
        }
        prompt = RedmineAiHelper::Util::PromptLoader.load_template("leader_agent/system_prompt")
        prompt_text = prompt.format(
          lang: I18n.t(:general_lang_name),
          time: Time.now.iso8601,
          site_info: site_info_json(project: @project),
          current_page_info: current_page_info_string(),
          current_user: User.current,
          current_user_info: current_user_info,
          additional_system_prompt: AiHelperSetting.find_or_create.additional_instructions,
        )

        prompt_text
      end

      private

      # Generates a string that describes the current page information.
      # @return [String] A string that describes the current page information.
      # @note This method is used to provide context to the AI about the current page.
      def current_page_info_string()
        page_name = nil
        case @controller_name
        when "projects"
          page_name = "プロジェクト「#{@project.name}」の情報ページです" # TODO: 英語にする
        when "issues"
          case @action_name
          when "show"
            issue = Issue.find(@content_id)
            page_name = "チケット ##{issue.id} の詳細\nユーザが特にIDや名前を指定せずにただ「チケット」といった場合にはこのチケットのことです。" # TODO: 英語にする
          when "index"
            page_name = "チケット一覧" # TODO: 英語にする
          else
            page_name = "チケットの#{@action_name}ページです" # TODO: 英語にする
          end
        when "wiki"
          case @action_name
          when "show"
            page = WikiPage.find(@content_id)
            page_name = "「#{page.title}」というタイトルのWikiページを表示しています。\nユーザが特にタイトルを指定せずにただ「Wikiページ」や「ページ」といった場合にはこのWikiページのことです。" # TODO: 英語にする
          end
        when "repositories"
          repo = Repository.find(@content_id)
          case @action_name
          when "show"
            page_name = "リポジトリ「#{repo.name}」の情報ページです。リポジトリのIDは #{repo.id} です。" # TODO: 英語にする
          when "entry"
            page_name = "リポジトリのファイル情報のページです。表示しているファイルパスは #{@additional_info["path"]} です。リビジョンは #{@additional_info["rev"]} です。リポジトリは「 #{repo.name}」です。リポジトリのIDは #{repo.id} です。" # TODO: 英語にする
          when "diff"
            page_name = "リポジトリ「#{repo.name}」の変更差分ページです。リポジトリのIDは #{repo.id} です。" # TODO: 英語にする
            page_name += "リビジョンは #{@additional_info["rev"]} です。" unless @additional_info["rev_to"] # TODO: 英語にする
            page_name += "リビジョンは #{@additional_info["rev"]} から #{@additional_info["rev_to"]} です。" if @additional_info["rev_to"] # TODO: 英語にする
            page_name += "ファイルパスは #{@additional_info["path"]} です。" if @additional_info["path"] # TODO: 英語にする
          when "revision"
            page_name = "リポジトリ「#{repo.name}」のリビジョン情報ページです。リビジョンは #{@additional_info["rev"]} です。リポジトリのIDは #{repo.id} です。" # TODO: 英語にする
          else
            page_name = "リポジトリの情報ページです" # TODO: 英語にする
          end
        when "boards"
          board = Board.find(@content_id) if @content_id
          case @action_name
          when "show"
            page_name = "フォーラム「#{board.name}」のページです。フォーラムのIDは #{board.id} です。" # TODO: 英語にする
          when "index"
            if board
              page_name = "フォーラム「#{board.name}」のページです。フォーラムのIDは #{board.id} です。" # TODO: 英語にする
            else
              page_name = "フォーラム一覧のページです。" # TODO: 英語にする
            end
          else
            page_name = "フォーラムのページです。" # TODO: 英語にする
          end
        when "messages"
          message = Message.find(@content_id) if @content_id
          page_name = "メッセージ「#{message.subject}」のページです。メッセージのIDは #{message.id}です。" if message # TODO: 英語にする
          page_name = "メッセージのページです。" unless message # TODO: 英語にする
        when "versions"
          version = Version.find(@content_id) if @content_id
          page_name = "バージョン「#{version.name}」のページです。バージョンのIDは #{version.id} です。" if version # TODO: 英語にする
          page_name ||= "バージョンのページです。" # TODO: 英語にする
        else
          page_name = "#{@controller_name}の#{@action_name}ページです" # TODO: 英語にする
        end

        return "" if page_name.nil?
        # TODO: 英語にする
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
            redmine_version: Redmine::VERSION::STRING,
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
