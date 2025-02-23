require File.expand_path("../../../test_helper", __FILE__)

class IssueUpdateToolProviderTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users,  :issue_categories, :versions, :custom_fields

  def setup
    @provider = RedmineAiHelper::ToolProviders::IssueUpdateToolProvider.new
  end

  context "IssueUpdateToolProvider" do
    should "list tools" do
      tools = @provider.class.list_tools
      assert tools[:tools].any? { |tool| tool[:name] == "create_new_issue" }
      assert tools[:tools].any? { |tool| tool[:name] == "update_issue" }
    end


    context "create_new_issue" do
      should "create issue" do
        response = @provider.create_new_issue(project_id: 1, tracker_id: 1, status_id: 1,subject: "test issue", description: "test description")
        assert response.is_success?
        assert response.value[:id].present?
      end

      should "return error with invalid project" do
        response = @provider.create_new_issue(project_id: 999, tracker_id: 1, status_id: 1, subject: "test issue", description: "test description")
        assert response.is_error?
        assert_equal "Project not found. id = 999", response.error
      end

      should "return error with invalid tracker" do
        response = @provider.create_new_issue(project_id: 1, tracker_id: 999, status_id: 1, subject: "test issue", description: "test description")
        assert response.is_error?
        assert response.error.include?("Tracker")
      end

      should "return error with invalid subject" do
        response = @provider.create_new_issue(project_id: 1, tracker_id: 1, status_id: 1, subject: "", description: "test description")
        assert response.is_error?
        assert response.error.include?("Subject")
      end

      should "create issue with custom fields" do
        response = @provider.create_new_issue(project_id: 1, tracker_id: 1, status_id: 1, subject: "test issue", description: "test description", custom_fields: [{ field_id: 1, value: "MySQL" }])
        assert response.is_success?
        assert response.value[:id].present?
      end

      context "validate_only is true" do
        should "validate issue" do
          response = @provider.create_new_issue({project_id: 1, tracker_id: 1, status_id: 1, subject: "test issue", description: "test description"}, true)
          assert response.is_success?
          assert response.value[:issue_id].nil?
        end

        should "return error with invalid project" do
          response = @provider.create_new_issue({project_id: 1, tracker_id: 999, status_id: 1, subject: "test issue", description: "test description"}, true)
          assert response.is_error?
          assert response.error.include?("Validation failed")
          assert response.error.include?("Tracker")
        end
      end
    end

    context "update_issue" do
      should "update issue" do
        issue = Issue.find(1)
        response = @provider.update_issue(issue_id: 1, subject: "test issue")
        assert response.is_success?
        assert_equal "test issue", Issue.find(issue.id).subject
      end

      should "return error with invalid id" do
        response = @provider.update_issue(issue_id: 999, subject: "test issue")
        assert response.is_error?
        assert_equal "Issue not found. id = 999", response.error
      end

      should "return error with invalid subject" do
        response = @provider.update_issue(issue_id: 1, subject: "")
        assert response.is_error?
        assert response.error.include?("Subject")
      end

      should "update issue with custom fields" do
        response = @provider.update_issue(issue_id: 1, subject: "test issue", custom_fields: [{ field_id: 1, value: "MySQL" }])
        assert response.is_success?
        assert_equal "MySQL", Issue.find(1).custom_field_values.filter { |cfv| cfv.custom_field_id == 1 }.first.value
      end

      should "update issue with comment_to_add" do
        issue = Issue.find(1)
        original_journal_count = issue.journals.size
        response = @provider.update_issue(issue_id: issue.id, subject: "test issue", comment_to_add: "test comment")
        assert response.is_success?
        assert_equal "test issue", Issue.find(1).subject
        assert_equal original_journal_count + 1, Issue.find(1).journals.size
        assert_equal "test comment", Issue.find(1).journals[original_journal_count].notes
      end

      context "validate_only is true" do
        should "validate issue" do
          issue = Issue.find(1)
          original_subject = issue.subject
          response = @provider.update_issue({issue_id: 1, subject: "test issue"}, true)
          assert response.is_success?
          assert_equal original_subject, Issue.find(1).subject
        end

        should "return error with invalid id" do
          response = @provider.update_issue({issue_id: 1, tracker_id: 999, subject: "test issue"}, true)
          assert response.is_error?
          assert response.error.include?("Validation failed")
          assert response.error.include?("Tracker")
        end
      end
    end
  end
end
