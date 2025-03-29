require File.expand_path("../../../test_helper", __FILE__)

class ProjectToolProviderTest < ActiveSupport::TestCase
  fixtures :projects, :projects_trackers, :trackers, :users, :repositories, :changesets, :changes, :issues, :issue_statuses, :enumerations, :issue_categories, :trackers

  def setup
    @provider = RedmineAiHelper::Tools::ProjectToolProvider.new
    enabled_module = EnabledModule.new
    enabled_module.project_id = 1
    enabled_module.name = "ai_helper"
    enabled_module.save!
    User.current = User.find(1)
  end

  def test_list_projects
    enabled_module = EnabledModule.new
    enabled_module.project_id = 2
    enabled_module.name = "ai_helper"
    enabled_module.save!

    response = @provider.list_projects()
    assert_equal 2, response.content.size
    project1 = Project.find(1)
    project2 = Project.find(2)
    [project1, project2].each_with_index do |project, index|
      value = response.content[index]
      assert_equal project.id, value[:id]
      assert_equal project.name, value[:name]
    end
  end

  def test_read_project_by_id
    project = Project.find(1)

    response = @provider.read_project(project_id: project.id)
    assert_equal project.id, response.content[:id]
    assert_equal project.name, response.content[:name]
  end

  def test_read_project_by_name
    project = Project.find(1)

    response = @provider.read_project(project_name: project.name)
    assert_equal project.id, response.content[:id]
    assert_equal project.name, response.content[:name]
  end

  def test_read_project_by_identifier
    project = Project.find(1)

    response = @provider.read_project(project_identifier: project.identifier)
    assert_equal project.id, response.content[:id]
    assert_equal project.name, response.content[:name]
  end

  def test_read_project_not_found
    assert_raises(RuntimeError, "Project not found") do
      @provider.read_project(project_id: 999)
    end
  end

  def test_read_project_no_args
    assert_raises(RuntimeError, "No id or name or Identifier specified.") do
      @provider.read_project
    end
  end

  def test_project_members
    project = Project.find(1)
    members = project.members

    response = @provider.project_members(project_ids: [project.id])
    assert_equal members.size, response.content[:projects][0][:members].size
    assert_equal members.first.user_id, response.content[:projects][0][:members].first[:user_id]
  end

  def test_project_enabled_modules
    project = Project.find(1)
    enabled_modules = project.enabled_modules

    response = @provider.project_enabled_modules(project_id: project.id)
    assert_equal enabled_modules.size, response.content[:enabled_modules].size
    assert_equal enabled_modules.first.name, response.content[:enabled_modules].first[:name]
  end

  def test_list_project_activities
    assert_nothing_raised do
      project = Project.find(1)
      @provider.list_project_activities(project_id: project.id)

      author = User.find(1)
      @provider.list_project_activities(project_id: project.id, author_id: author.id)
    end
  end


end
