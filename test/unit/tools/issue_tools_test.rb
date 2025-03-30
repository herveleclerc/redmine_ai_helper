require File.expand_path("../../../test_helper", __FILE__)

class IssueToolsTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users,  :issue_categories, :versions, :custom_fields

  def setup
    @provider = RedmineAiHelper::Tools::IssueTools.new
  end

  context "IssueTool" do

    context "read_issues" do
      should "return issues" do
        issue = Issue.find(1)
        response = @provider.read_issues(issue_ids: [1])
        assert_equal 1, response.content[:issues].size
        assert_equal issue.id, response.content[:issues].first[:id]
      end

      should "return error with invalid id" do
        assert_raises(RuntimeError, "Issue not found") do
          @provider.read_issues(issue_ids: [999])
        end
      end
    end

    context "capable_issue_properties" do
      should "return properties with project id" do
        project = Project.find(1)
        response = @provider.capable_issue_properties(project_id: 1)
        assert_equal project.trackers.size, response.content[:trackers].size
        assert_equal project.issue_categories.size, response.content[:categories].size
      end

      should "return properties with project name" do
        project = Project.find(1)
        response = @provider.capable_issue_properties(project_name: project.name)
        assert_equal project.trackers.size, response.content[:trackers].size
        assert_equal project.issue_categories.size, response.content[:categories].size
      end

      should "return properties with project identifier" do
        project = Project.find(1)
        response = @provider.capable_issue_properties(project_identifier: project.identifier)
        assert_equal project.trackers.size, response.content[:trackers].size
        assert_equal project.issue_categories.size, response.content[:categories].size
      end

      should "return error with invalid project" do
        assert_raises(RuntimeError, "No id or name or Identifier specified.") do
          @provider.capable_issue_properties(project_id: 999)
        end

        assert_raises(RuntimeError, "Project not found.") do
          @provider.capable_issue_properties(project_id: 999)
        end
      end
    end

    context "generate_issue_search_url" do
      should "generate url with filters" do
        project = Project.find(1)
        response = @provider.generate_issue_search_url(project_id: 1, fields: [{ field_name: "tracker_id", operator: "=", values: ["1"] }])
        assert_match "/projects/#{project.identifier}/issues?set_filter=1", response.content[:url]
      end

      should "generate url with no filters" do
        project = Project.find(1)
        response = @provider.generate_issue_search_url(project_id: 1)
        assert_equal "/projects/#{project.identifier}/issues", response.content[:url]
      end

      should "generate url with date fields" do
        response = @provider.generate_issue_search_url(project_id: 1, date_fields: [{ field_name: "created_on", operator: ">=", values: ["2020-01-01"] }])
        url_value = CGI.unescape(response.content[:url])
        assert url_value.include?("f[]=created_on")
        assert url_value.include?("op[created_on]=>")
        assert url_value.include?("v[created_on][]=2020-01-01")
      end

      should "generate url with time fields" do
        response = @provider.generate_issue_search_url(project_id: 1, time_fields: [{ field_name: "estimated_hours", operator: "=", values: ["6"] }])
        url_value = CGI.unescape(response.content[:url])
        assert url_value.include?("f[]=estimated_hours")
        assert url_value.include?("op[estimated_hours]==")
        assert url_value.include?("v[estimated_hours][]=6")
      end

      should "generate url with number fields" do
        response = @provider.generate_issue_search_url(project_id: 1, number_fields: [{ field_name: "done_ratio", operator: "=", values: ["6"] }])
        url_value = CGI.unescape(response.content[:url])
        assert url_value.include?("f[]=done_ratio")
        assert url_value.include?("op[done_ratio]==")
        assert url_value.include?("v[done_ratio][]=6")
      end

      should "generate url with text fields" do
        response = @provider.generate_issue_search_url(project_id: 1, text_fields: [{ field_name: "subject", operator: "~", value: ["test"] }])
        url_value = CGI.unescape(response.content[:url])
        assert url_value.include?("f[]=subject")
        assert url_value.include?("op[subject]=~")
        # TODO: Fix this test
        # assert url_value.include?("v[subject][]=test")
      end

      should "generate url with status fields" do
        response = @provider.generate_issue_search_url(project_id: 1, status_field: [{ field_name: "status_id", operator: "=", values: [1] }])
        url_value = CGI.unescape(response.content[:url])
        assert url_value.include?("f[]=status_id")
        assert url_value.include?("op[status_id]==")
        assert url_value.include?("v[status_id][]=1")
      end

      should "generate url with custom field" do
        response = @provider.generate_issue_search_url(project_id: 1, custom_fields: [{ field_id: 1, operator: "=", values: ["MySQL"] }])
        url_value = CGI.unescape(response.content[:url])
        assert url_value.include?("f[]=cf_1")
        assert url_value.include?("op[cf_1]==")
        assert url_value.include?("v[cf_1][]=MySQL")
      end
    end

    context "validate_new_issue" do
      should "validate issue" do
        response = @provider.validate_new_issue(project_id: 1, tracker_id: 1, status_id: 1, subject: "test issue", description: "test description")
        assert response.content[:issue_id].nil?
      end

      should "return error with invalid project" do
        assert_raises(RuntimeError, "Validation failed") do
          @provider.validate_new_issue(project_id: 999, tracker_id: 1, status_id: 1, subject: "test issue", description: "test description")
        end
      end
    end

    context "validate_update_issue" do
      should "validate issue" do
        issue = Issue.find(1)
        original_subject = issue.subject
        @provider.validate_update_issue(issue_id: 1, subject: "test issue")
        assert_equal original_subject, Issue.find(issue.id).subject
      end

      should "return error with invalid issue" do
        assert_raises(RuntimeError, "Issue not found") do
          @provider.validate_update_issue(issue_id: 999, subject: "test issue")
        end
      end
    end
  end
end
