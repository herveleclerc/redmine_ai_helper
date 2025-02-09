require File.expand_path('../../test_helper', __FILE__)

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
    options = { controller_name: 'projects', action_name: 'show', project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /プロジェクト「#{@project.name}」の情報ページです/, prompt
  end

  def test_prompt_with_issue_page
    options = { controller_name: 'issues', action_name: 'show', content_id: @issue.id, project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /チケット ##{@issue.id} の詳細/, prompt
  end

  def test_prompt_with_issue_index_page
    options = { controller_name: 'issues', action_name: 'index', project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /チケット一覧/, prompt
  end

  def test_prompt_with_issue_new_page
    options = { controller_name: 'issues', action_name: 'new', project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /チケットのnewページです/, prompt
  end

  def test_prompt_with_wiki_page
    options = { controller_name: 'wiki', action_name: 'show', content_id: @wiki_page.id, project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /「#{@wiki_page.title}」というタイトルのWikiページを表示しています/, prompt
  end

  def test_prompt_with_repository_page
    options = { controller_name: 'repositories', action_name: 'show', content_id: @repository.id, project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /リポジトリ「#{@repository.name}」の情報ページです/, prompt
  end

  def test_prompt_with_repository_entry_page
    options = { controller_name: 'repositories', action_name: 'entry', content_id: @repository.id, additional_info: { "path" => "path/to/file", "rev" => "123" }, project: @project }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /リポジトリのファイル情報のページです。表示しているファイルパスは path\/to\/file です。リビジョンは 123 です。リポジトリは「 #{@repository.name}」です。/, prompt
  end

  def test_prompt_with_repository_other_page
    options = { controller_name: 'repositories', action_name: 'other', project: @project, content_id: @repository.id }
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new(options)
    prompt = system_prompt.prompt
    assert_match /リポジトリの情報ページです/, prompt
  end

  def test_site_info_json
    system_prompt = RedmineAiHelper::Util::SystemPrompt.new
    json = system_prompt.site_info_json(project: @project)
    assert_match /"title": "#{Setting.app_title}"/, json
    assert_match /"current_project": {/, json
    assert_match /"name": "#{@project.name}"/, json
  end
end
