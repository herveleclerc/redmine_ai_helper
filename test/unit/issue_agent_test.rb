require File.expand_path("../../test_helper", __FILE__)

class IssueAgentTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields

  def setup
    @agent = RedmineAiHelper::Agents::IssueAgent.new
  end

  def test_list_tools
    tools = @agent.class.list_tools
    assert tools[:tools].any? { |tool| tool[:name] == "read_issues" }
    assert tools[:tools].any? { |tool| tool[:name] == "capable_issue_properties" }
    assert tools[:tools].any? { |tool| tool[:name] == "generate_issue_search_url" }
  end

  def test_read_issues
    issue = Issue.find(1)
    response = @agent.read_issues(id: [1])
    assert response.is_success?
    assert_equal 1, response.value[:issues].size
    assert_equal issue.id, response.value[:issues].first[:id]
  end

  def test_read_issues_with_invalid_id
    response = @agent.read_issues(id: [])
    assert response.is_error?
    assert_equal "Issue ID array is required.", response.error
  end

  def test_capable_issue_properties
    project = Project.find(1)
    response = @agent.capable_issue_properties(project_id: 1)
    assert response.is_success?
    assert_equal project.trackers.size, response.value[:trackers].size
    assert_equal project.issue_categories.size, response.value[:categories].size
  end

  def test_capable_issue_properties_with_invalid_project
    response = @agent.capable_issue_properties({})
    assert response.is_error?
    assert_equal "No id or name or Identifier specified.", response.error

    response = @agent.capable_issue_properties(project_id: 999)
    assert response.is_error?
    assert_equal "Project not found.", response.error
  end

  def test_generate_issue_search_url
    project = Project.find(1)
    response = @agent.generate_issue_search_url(project_id: 1, fields: [{ field_name: "tracker_id", operator: "=", values: ["1"] }])
    assert response.is_success?
    assert_match "/projects/#{project.identifier}/issues?set_filter=1", response.value[:url]
  end

  def test_generate_issue_search_url_with_no_filters
    project = Project.find(1)
    response = @agent.generate_issue_search_url(project_id: 1)
    assert response.is_success?
    assert_equal "/projects/#{project.identifier}/issues", response.value[:url]
  end
end
