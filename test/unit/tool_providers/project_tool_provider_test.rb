require File.expand_path("../../../test_helper", __FILE__)

class ProjectToolProviderTest < ActiveSupport::TestCase
  fixtures :projects, :users, :repositories, :changesets, :changes, :issues, :issue_statuses, :enumerations, :issue_categories, :trackers

  def setup
    @provider = RedmineAiHelper::ToolProviders::ProjectToolProvider.new
    enabled_module = EnabledModule.new
    enabled_module.project_id = 1
    enabled_module.name = "ai_helper"
    enabled_module.save!
    User.current = User.find(1)
  end

  def test_list_projects
    projects = Project.all

    response = @provider.list_projects
    assert response.is_success?
    assert_equal projects.size, response.value.size
    projects.each_with_index do |project, index|
      assert_equal project.id, response.value[index][:id]
      assert_equal project.name, response.value[index][:name]
    end
  end

  def test_read_project_by_id
    project = Project.find(1)

    response = @provider.read_project(id: project.id)
    assert response.is_success?
    assert_equal project.id, response.value[:id]
    assert_equal project.name, response.value[:name]
  end

  def test_read_project_by_name
    project = Project.find(1)

    response = @provider.read_project(name: project.name)
    assert response.is_success?
    assert_equal project.id, response.value[:id]
    assert_equal project.name, response.value[:name]
  end

  def test_read_project_by_identifier
    project = Project.find(1)

    response = @provider.read_project(identifier: project.identifier)
    assert response.is_success?
    assert_equal project.id, response.value[:id]
    assert_equal project.name, response.value[:name]
  end

  def test_read_project_not_found
    response = @provider.read_project(id: 999)
    assert response.is_error?
    assert_equal "Project not found", response.error
  end

  def test_read_project_no_args
    response = @provider.read_project
    assert response.is_error?
    assert_equal "No id or name or Identifier specified.", response.error
  end

  def test_project_members
    project = Project.find(1)
    members = project.members

    response = @provider.project_members(project_ids: [project.id])
    assert response.is_success?
    assert_equal members.size, response.value[:projects][0][:members].size
    assert_equal members.first.user_id, response.value[:projects][0][:members].first[:user_id]
  end

  def test_project_enabled_modules
    project = Project.find(1)
    enabled_modules = project.enabled_modules

    response = @provider.project_enabled_modules(project_id: project.id)
    assert response.is_success?
    assert_equal enabled_modules.size, response.value[:enabled_modules].size
    assert_equal enabled_modules.first.name, response.value[:enabled_modules].first[:name]
  end

  def test_list_project_activities
    project = Project.find(1)
    response = @provider.list_project_activities(project_id: project.id)
    assert response.is_success?

    author = User.find(1)
    response = @provider.list_project_activities(project_id: project.id, author_id: author.id)
    assert response.is_success?
    # assert_equal project.list_project_activities.size, response.value[:activities].size
  end

  def test_self_list_tools
    response = RedmineAiHelper::ToolProviders::ProjectToolProvider.list_tools
    assert_equal 5, response[:tools].size
    assert_equal "list_projects", response[:tools].first[:name]
    assert_equal "read_project", response[:tools].second[:name]
    assert_equal "project_members", response[:tools].third[:name]
    assert_equal "project_enabled_modules", response[:tools].fourth[:name]
    assert_equal "list_project_activities", response[:tools].fifth[:name]
  end
end
