require File.expand_path("../../test_helper", __FILE__)

class VersionToolProviderTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :boards, :messages

  def setup
    @provider = RedmineAiHelper::ToolProviders::VersionToolProvider.new
    @project = Project.find(1)
    @version = @project.versions.first
  end

  def test_list_versions_success
    args = { project_id: @project.id }
    response = @provider.list_versions(args)
    assert response.is_success?
    assert_equal @project.versions.count, response.value.size
  end

  def test_list_versions_project_not_found
    args = { project_id: 999 }
    response = @provider.list_versions(args)
    assert response.is_error?
    assert_equal "Project not found", response.error
  end

  def test_version_info_success
    args = { version_id: @version.id }
    response = @provider.version_info(args)
    assert response.is_success?
    assert_equal @version.id, response.value[:id]
    assert_equal @version.name, response.value[:name]
  end

  def test_version_info_not_found
    args = { version_id: 999 }
    response = @provider.version_info(args)
    assert response.is_error?
    assert_equal "Version not found", response.error
  end

  def test_list_tools
    tools = RedmineAiHelper::ToolProviders::VersionToolProvider.list_tools
    assert_not_nil tools
    assert_equal "list_versions", tools[:tools].first[:name]
    assert_equal "version_info", tools[:tools].second[:name]
  end
end
