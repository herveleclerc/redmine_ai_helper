require File.expand_path("../../test_helper", __FILE__)

class RepositoryAgentTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :repositories, :changesets, :changes

  def setup
    @agent = RedmineAiHelper::Agents::RepositoryAgent.new
    repo_dir = Rails.root.join("plugins/redmine_ai_helper/tmp", "redmine_ai_helper_test_repo.git").to_s
    @project = Project.find(1)
    # @repository = Repository::Git.new(
    #   project: @project,
    #   url: repo_dir,
    #   root_url: repo_dir,
    #   identifier: "test",
    # )
    # @repository.save!
    @repository = @project.create_repository(
      type: "Repository::Git",
      url: repo_dir,
      identifier: "test",
    )
  end

  def test_repository_info_success
    repository = @repository
    args = { repository_id: repository.id }
    response = @agent.repository_info(args)
    assert response.is_success?
    assert_equal repository.id, response.value[:id]
    assert_equal "Git", response.value[:type]
    assert_equal "test", response.value[:name]
  end

  def test_repository_info_not_found
    args = { repository_id: 999 }
    response = @agent.repository_info(args)
    assert response.is_error?
    assert_equal "Repository not found.", response.error
  end

  def test_get_file_info_success
    repository = @repository
    args = { repository_id: repository.id, path: "README.md", revision: "main" }
    response = @agent.get_file_info(args)
    assert response.is_success?
    assert_equal 119, response.value[:size]
    assert_equal "file", response.value[:type]
    assert response.value[:is_text]
  end

  def test_get_file_info_not_found
    repository = @repository
    repository.stubs(:entry).returns(nil)
    args = { repository_id: repository.id, path: "nonexistent.txt", revision: "main" }
    response = @agent.get_file_info(args)
    assert response.is_error?
    assert_equal "File not found: path = nonexistent.txt, revision = main", response.error
  end

  def test_read_file_success
    repository = @repository
    args = { repository_id: repository.id, path: "README.md", revision: "main" }
    response = @agent.read_file(args)
    assert response.is_success?
    assert response.value[:content].include?("some text")
  end

  def test_read_file_not_found
    repository = @repository
    repository.stubs(:entry).returns(nil)
    args = { repository_id: repository.id, path: "nonexistent.txt", revision: "main" }
    response = @agent.read_file(args)
    assert response.is_error?
    assert_equal "File not found: path = nonexistent.txt, revision = main", response.error
  end

  def test_read_file_not_text
    repository = @repository
    args = { repository_id: repository.id, path: "test_dir/hello.zip", revision: "main" }
    response = @agent.read_file(args)
    assert response.is_error?
    assert_equal "File is not text: path = test_dir/hello.zip, revision = main", response.error
  end
end
