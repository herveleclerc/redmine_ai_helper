require File.expand_path("../../test_helper", __FILE__)

class ProjectAgentTest < ActiveSupport::TestCase
  fixtures :projects, :users, :repositories, :changesets, :changes, :issues, :issue_statuses, :enumerations, :issue_categories, :trackers

  def setup
    @agent = RedmineAiHelper::Agents::ProjectAgent.new
  end

  def test_list_projects
    projects = Project.all
    projects.each { |p| p.stubs(:visible?).returns(true) }

    response = @agent.list_projects
    assert response.is_success?
    assert_equal projects.size, response.value.size
    projects.each_with_index do |project, index|
      assert_equal project.id, response.value[index][:id]
      assert_equal project.name, response.value[index][:name]
    end
  end

  def test_read_project_by_id
    project = Project.find(1)

    response = @agent.read_project(id: project.id)
    assert response.is_success?
    assert_equal project.id, response.value[:id]
    assert_equal project.name, response.value[:name]
  end

  def test_read_project_by_name
    project = Project.find(1)
    project.stubs(:visible?).returns(true)

    response = @agent.read_project(name: project.name)
    assert response.is_success?
    assert_equal project.id, response.value[:id]
    assert_equal project.name, response.value[:name]
  end

  def test_read_project_not_found
    response = @agent.read_project(id: 999)
    assert response.is_error?
    assert_equal "Project not found", response.error
  end

  def test_project_members
    project = Project.find(1)
    members = project.members

    response = @agent.project_members(project_id: project.id)
    assert response.is_success?
    assert_equal members.size, response.value[:members].size
    assert_equal members.first.user_id, response.value[:members].first[:user_id]
  end

  def test_project_enabled_modules
    project = Project.find(1)
    enabled_modules = project.enabled_modules

    response = @agent.project_enabled_modules(project_id: project.id)
    assert response.is_success?
    assert_equal enabled_modules.size, response.value[:enabled_modules].size
    assert_equal enabled_modules.first.name, response.value[:enabled_modules].first[:name]
  end

  def test_list_project_activities
    project = Project.find(1)
    response = @agent.list_project_activities(project_id: project.id)
    assert response.is_success?

    author = User.find(1)
    response = @agent.list_project_activities(project_id: project.id, author_id: author.id)
    assert response.is_success?
    # assert_equal project.list_project_activities.size, response.value[:activities].size
  end
end
