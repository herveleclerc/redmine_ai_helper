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
      json_text = @vector_db.data_to_jsontext(@issue)
      json_data = JSON.parse(json_text)

      assert_equal @issue.id, json_data["id"]
      assert_equal @issue.project.name, json_data["project_name"]
      assert_equal @issue.author&.name, json_data["author_name"]
      assert_equal @issue.subject, json_data["subject"]
      assert_equal @issue.description, json_data["description"]
      assert_equal @issue.status.name, json_data["status"]
      assert_equal @issue.priority.name, json_data["priority"]
      assert_equal @issue.assigned_to.name, json_data["assigned_to_name"]
      assert_equal @issue.created_on, json_data["created_on"]
      assert_equal @issue.updated_on, json_data["updated_on"]
      assert_equal @issue.tracker.name, json_data["tracker_name"]

      # Test comments (journals)
      assert_equal @issue.journals.size, json_data["comments"].size
      @issue.journals.each_with_index do |journal, index|
        assert_equal journal.user&.name, json_data["comments"][index]["user_name"]
        assert_equal journal.notes, json_data["comments"][index]["notes"]
        assert_equal journal.created_on, json_data["comments"][index]["created_on"]
      end
    end
  end
end
