require_relative "../test_helper"
require "redmine_ai_helper/agent"
require "redmine_ai_helper/llm"

class AgentTest < ActiveSupport::TestCase
  def setup
    @llm = RedmineAiHelper::Llm.new
    @agent = RedmineAiHelper::Agent.new(@llm)
  end

  def test_callTool
    assert_raise(RuntimeError) { @agent.callTool(name: "not_exist") }
    issue_json = @agent.callTool(name: "read_issue", arguments: { id: Issue.first.id })
    assert_equal Issue.first.id, issue_json[:id]
    project_json = @agent.callTool(name: "read_project", arguments: { id: Project.first.id })
    assert_equal Project.first.id, project_json[:id]
  end

  def test_read_issue
    issue = Issue.first
    issue_json = @agent.read_issue(id: issue.id)
    assert_equal issue.id, issue_json[:id]
    assert_equal issue.subject, issue_json[:subject]
    assert_equal issue.project.id, issue_json[:project][:id]
    assert_equal issue.project.name, issue_json[:project][:name]
    assert_equal issue.tracker.id, issue_json[:tracker][:id]
    assert_equal issue.tracker.name, issue_json[:tracker][:name]
    assert_equal issue.status.id, issue_json[:status][:id]
    assert_equal issue.status.name, issue_json[:status][:name]
    assert_equal issue.priority.id, issue_json[:priority][:id]
    assert_equal issue.priority.name, issue_json[:priority][:name]
    assert_equal issue.author.id, issue_json[:author][:id]
    assert_equal issue.author.name, issue_json[:author][:name]
    assert_equal issue.description, issue_json[:description]
    assert_equal issue.start_date, issue_json[:start_date]
    assert_equal issue.due_date, issue_json[:due_date]
    assert_equal issue.done_ratio, issue_json[:done_ratio]
    assert_equal issue.is_private, issue_json[:is_private]
    assert_equal issue.estimated_hours, issue_json[:estimated_hours]
    assert_equal issue.total_estimated_hours, issue_json[:total_estimated_hours]
    assert_equal issue.spent_hours, issue_json[:spent_hours]
    assert_equal issue.total_spent_hours, issue_json[:total_spent_hours]
    assert_equal issue.created_on, issue_json[:created_on]
    assert_equal issue.updated_on, issue_json[:updated_on]
    assert_equal issue.closed_on, issue_json[:closed_on]
  end

  def test_read_project
    project = Project.first
    project_json = @agent.read_project(id: project.id)
    assert_equal project.id, project_json[:id]
    assert_equal project.name, project_json[:name]
    assert_equal project.description, project_json[:description]
    assert_equal project.homepage, project_json[:homepage]
    assert_equal project.is_public, project_json[:is_public]
    assert_equal project.parent_id, project_json[:parent_id]
    assert_equal project.created_on, project_json[:created_on]
    assert_equal project.updated_on, project_json[:updated_on]
  end
end
