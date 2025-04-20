require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/vector/issue_vector_db"

class RedmineAiHelper::Vector::IssueVectorDbTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :journals

  context "IssueVectorDb" do
    setup do
      @issue = Issue.find(1)
      @issue.assigned_to = User.find(2)
      @vector_db = RedmineAiHelper::Vector::IssueVectorDb.new
    end

    should "return correct index name" do
      assert_equal "RedmineIssue", @vector_db.index_name
    end

    should "convert issue data to JSON text" do
      json_data = @vector_db.data_to_json(@issue)

      payload = json_data[:payload]
      assert_equal @issue.id, payload[:issue_id]
      assert_equal @issue.project.name, payload[:project_name]
    end
  end
end
