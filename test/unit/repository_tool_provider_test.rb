require File.expand_path("../../test_helper", __FILE__)

class RepositoryToolProviderTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :repositories, :changesets, :changes

  def setup
    @provider = RedmineAiHelper::ToolProviders::RepositoryToolProvider.new
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
    @repository.fetch_changesets
    @repository.save!
  end

  def test_repository_info_success
    repository = @repository
    args = { repository_id: repository.id }
    response = @provider.repository_info(args)
    assert response.is_success?
    assert_equal repository.id, response.value[:id]
    assert_equal "Git", response.value[:type]
    assert_equal "test", response.value[:name]
  end

  def test_repository_info_not_found
    args = { repository_id: 999 }
    response = @provider.repository_info(args)
    assert response.is_error?
    assert_equal "Repository not found.", response.error
  end

  def test_get_file_info_success
    repository = @repository
    args = { repository_id: repository.id, path: "README.md", revision: "main" }
    response = @provider.get_file_info(args)
    assert response.is_success?
    assert_equal 119, response.value[:size]
    assert_equal "file", response.value[:type]
    assert response.value[:is_text]
  end

  def test_get_file_info_not_found
    repository = @repository
    args = { repository_id: repository.id, path: "nonexistent.txt", revision: "main" }
    response = @provider.get_file_info(args)
    assert response.is_error?
    assert_equal "File not found: path = nonexistent.txt, revision = main", response.error
  end

  def test_read_file_success
    repository = @repository
    args = { repository_id: repository.id, path: "README.md", revision: "main" }
    response = @provider.read_file(args)
    assert response.is_success?
    assert response.value[:content].include?("some text")
  end

  def test_read_file_not_found
    repository = @repository
    args = { repository_id: repository.id, path: "nonexistent.txt", revision: "main" }
    response = @provider.read_file(args)
    assert response.is_error?
    assert_equal "File not found: path = nonexistent.txt, revision = main", response.error
  end

  def test_read_file_not_text
    repository = @repository
    args = { repository_id: repository.id, path: "test_dir/hello.zip", revision: "main" }
    response = @provider.read_file(args)
    assert response.is_error?
    assert_equal "File is not text: path = test_dir/hello.zip, revision = main", response.error
  end

  def test_list_tools
    tools = RedmineAiHelper::ToolProviders::RepositoryToolProvider.list_tools
    assert_not_nil tools
    assert_equal "repository_info", tools[:tools].first[:name]
    assert_equal "get_file_info", tools[:tools].second[:name]
    assert_equal "get_revision_info", tools[:tools].third[:name]
    assert_equal "read_file", tools[:tools].fourth[:name]
    assert_equal "read_diff", tools[:tools].fifth[:name]
  end

  def test_get_revision_info_success
    repository = @repository
    changeset = repository.changesets.second
    revision = changeset.revision
    args = { repository_id: repository.id, revision: revision }
    response = @provider.get_revision_info(args)
    assert response.is_success?
    assert_equal revision, response.value[:revision]
    assert_equal changeset.committed_on, response.value[:committed_on]
    assert_equal changeset.comments, response.value[:comments]
  end

  def test_get_revision_info_not_found
    args = { repository_id: 999, revision: "invalid_revision" }
    response = @provider.get_revision_info(args)
    assert response.is_error?
    assert_equal "Repository not found: repository_id = 999", response.error

    args = { repository_id: @repository.id, revision: "invalid_revision" }
    response = @provider.get_revision_info(args)
    assert response.is_error?
    assert_equal "Revision not found: revision = invalid_revision", response.error
  end
end
