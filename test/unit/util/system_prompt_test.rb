require File.expand_path("../../../test_helper", __FILE__)

class SystemPromptTest < ActiveSupport::TestCase
  fixtures :users, :projects, :issues, :repositories, :wiki_pages

  def setup
    @project = projects(:projects_001)
    @issue = issues(:issues_001)
    @wiki_page = wiki_pages(:wiki_pages_001)
    @repository = repositories(:repositories_001)
    @user = users(:users_001)
    User.current = @user
  end

  def test_prompt_with_project_page
    options = { controller_name: "projects", action_name: "show", project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /プロジェクト「#{@project.name}」の情報ページです/, prompt
  end

  def test_prompt_with_issue_page
    options = { controller_name: "issues", action_name: "show", content_id: @issue.id, project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /チケット ##{@issue.id} の詳細/, prompt
  end

  def test_prompt_with_issue_index_page
    options = { controller_name: "issues", action_name: "index", project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /チケット一覧/, prompt
  end

  def test_prompt_with_issue_new_page
    options = { controller_name: "issues", action_name: "new", project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /チケットのnewページです/, prompt
  end

  def test_prompt_with_wiki_page
    options = { controller_name: "wiki", action_name: "show", content_id: @wiki_page.id, project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /「#{@wiki_page.title}」というタイトルのWikiページを表示しています/, prompt
  end

  def test_prompt_with_repository_page
    options = { controller_name: "repositories", action_name: "show", content_id: @repository.id, project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /リポジトリ「#{@repository.name}」の情報ページです/, prompt
  end

  def test_prompt_with_repository_entry_page
    options = { controller_name: "repositories", action_name: "entry", content_id: @repository.id, additional_info: { "path" => "path/to/file", "rev" => "123" }, project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /リポジトリのファイル情報のページです。表示しているファイルパスは path\/to\/file です。リビジョンは 123 です。リポジトリは「 #{@repository.name}」です。/, prompt
  end

  def test_prompt_with_repository_diff_page
    options = { controller_name: "repositories", action_name: "diff", content_id: @repository.id, additional_info: { "rev" => "123", "rev_to" => "456", "path" => "path/to/file" }, project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /リポジトリ「#{@repository.name}」の変更差分ページです/, prompt
  end

  def test_prompt_with_repository_revision_page
    options = { controller_name: "repositories", action_name: "revision", content_id: @repository.id, additional_info: { "rev" => "123" }, project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /リポジトリ「#{@repository.name}」のリビジョン情報ページです/, prompt
  end

  def test_prompt_with_repository_other_page
    options = { controller_name: "repositories", action_name: "other", project: @project, content_id: @repository.id }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /リポジトリの情報ページです/, prompt
  end

  def test_prompt_with_board_page
    options = { controller_name: "boards", action_name: "show", content_id: 1, project: @project }
    board = Board.find(1)
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /フォーラム「#{board.name}」のページです。フォーラムのIDは #{board.id} です。/, prompt
  end

  def test_prompt_with_board_index_page
    options = { controller_name: "boards", action_name: "index", project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /フォーラム一覧のページです。/, prompt
  end

  def test_prompot_with_board_index_page_with_board
    options = { controller_name: "boards", action_name: "index", project: @project, content_id: 1 }
    board = Board.find(1)
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /フォーラム「#{board.name}」のページです。フォーラムのIDは #{board.id} です。/, prompt
  end

  def test_prompt_with_board_other_page
    options = { controller_name: "boards", action_name: "other", project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /フォーラムのページです/, prompt
  end

  def test_prompt_with_message_page
    options = { controller_name: "messages", action_name: "show", project: @project, content_id: 1 }
    message = Message.find(1)
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /メッセージ「#{message.subject}」のページです。メッセージのIDは #{message.id}です。/, prompt
  end

  def test_prompt_with_message_other_page
    options = { controller_name: "messages", action_name: "other", project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /メッセージのページです。/, prompt
  end

  def test_site_info_json
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new
    json = system_prompt.send(:site_info_json, project: @project)
    assert_match /"title": "#{Setting.app_title}"/, json
    assert_match /"current_project": {/, json
    assert_match /"name": "#{@project.name}"/, json
  end

  def test_prompt_with_version_page
    options = { controller_name: "versions", action_name: "show", project: @project, content_id: 1 }
    version = Version.find(1)
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /バージョン「#{version.name}」のページです。バージョンのIDは #{version.id} です。/, prompt
  end

  def test_prompt_with_version_other_page
    options = { controller_name: "versions", action_name: "other", project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /バージョンのページです/, prompt
  end
end
