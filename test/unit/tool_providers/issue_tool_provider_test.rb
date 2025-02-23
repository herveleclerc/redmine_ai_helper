require File.expand_path("../../../test_helper", __FILE__)

class IssueToolProviderTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users,  :issue_categories, :versions, :custom_fields

  def setup
    @provider = RedmineAiHelper::ToolProviders::IssueToolProvider.new
  end

  context "IssueToolProvider" do
    should "list tools" do
      tools = @provider.class.list_tools
      assert tools[:tools].any? { |tool| tool[:name] == "read_issues" }
      assert tools[:tools].any? { |tool| tool[:name] == "capable_issue_properties" }
      assert tools[:tools].any? { |tool| tool[:name] == "generate_issue_search_url" }
    end

    context "read_issues" do
      should "return issues" do
        issue = Issue.find(1)
        response = @provider.read_issues(id: [1])
        assert response.is_success?
        assert_equal 1, response.value[:issues].size
        assert_equal issue.id, response.value[:issues].first[:id]
      end

      should "return error with invalid id" do
        response = @provider.read_issues(id: [])
        assert response.is_error?
        assert_equal "Issue ID array is required.", response.error
      end
    end

    context "capable_issue_properties" do
      should "return properties with project id" do
        project = Project.find(1)
        response = @provider.capable_issue_properties(project_id: 1)
        assert response.is_success?
        assert_equal project.trackers.size, response.value[:trackers].size
        assert_equal project.issue_categories.size, response.value[:categories].size
      end

      should "return properties with project name" do
        project = Project.find(1)
        response = @provider.capable_issue_properties(project_name: project.name)
        assert response.is_success?
        assert_equal project.trackers.size, response.value[:trackers].size
        assert_equal project.issue_categories.size, response.value[:categories].size
      end

      should "return properties with project identifier" do
        project = Project.find(1)
        response = @provider.capable_issue_properties(project_identifier: project.identifier)
        assert response.is_success?
        assert_equal project.trackers.size, response.value[:trackers].size
        assert_equal project.issue_categories.size, response.value[:categories].size
      end

      should "return error with invalid project" do
        response = @provider.capable_issue_properties({})
        assert response.is_error?
        assert_equal "No id or name or Identifier specified.", response.error

        response = @provider.capable_issue_properties(project_id: 999)
        assert response.is_error?
        assert_equal "Project not found.", response.error
      end
    end

    context "generate_issue_search_url" do
      should "generate url with filters" do
        project = Project.find(1)
        response = @provider.generate_issue_search_url(project_id: 1, fields: [{ field_name: "tracker_id", operator: "=", values: ["1"] }])
        assert response.is_success?
        assert_match "/projects/#{project.identifier}/issues?set_filter=1", response.value[:url]
      end

      should "generate url with no filters" do
        project = Project.find(1)
        response = @provider.generate_issue_search_url(project_id: 1)
        assert response.is_success?
        assert_equal "/projects/#{project.identifier}/issues", response.value[:url]
      end

      should "generate url with date fields" do
        response = @provider.generate_issue_search_url(project_id: 1, date_fields: [{ field_name: "created_on", operator: ">=", values: ["2020-01-01"] }])
        assert response.is_success?
        url_value = CGI.unescape(response.value[:url])
        assert url_value.include?("f[]=created_on")
        assert url_value.include?("op[created_on]=>")
        assert url_value.include?("v[created_on][]=2020-01-01")
      end

      should "generate url with time fields" do
        response = @provider.generate_issue_search_url(project_id: 1, time_fields: [{ field_name: "estimated_hours", operator: "=", values: ["6"] }])
        assert response.is_success?
        url_value = CGI.unescape(response.value[:url])
        assert url_value.include?("f[]=estimated_hours")
        assert url_value.include?("op[estimated_hours]==")
        assert url_value.include?("v[estimated_hours][]=6")
      end

      should "generate url with number fields" do
        response = @provider.generate_issue_search_url(project_id: 1, number_fields: [{ field_name: "done_ratio", operator: "=", values: ["6"] }])
        assert response.is_success?
        url_value = CGI.unescape(response.value[:url])
        assert url_value.include?("f[]=done_ratio")
        assert url_value.include?("op[done_ratio]==")
        assert url_value.include?("v[done_ratio][]=6")
      end

      should "generate url with text fields" do
        response = @provider.generate_issue_search_url(project_id: 1, text_fields: [{ field_name: "subject", operator: "~", value: ["test"] }])
        assert response.is_success?
        url_value = CGI.unescape(response.value[:url])
        assert url_value.include?("f[]=subject")
        assert url_value.include?("op[subject]=~")
        # TODO: Fix this test
        # assert url_value.include?("v[subject][]=test")
      end

      should "generate url with status fields" do
        response = @provider.generate_issue_search_url(project_id: 1, status_field: [{ field_name: "status_id", operator: "=", values: [1] }])
        assert response.is_success?
        url_value = CGI.unescape(response.value[:url])
        assert url_value.include?("f[]=status_id")
        assert url_value.include?("op[status_id]==")
        assert url_value.include?("v[status_id][]=1")
      end
    end

    context "validate_new_issue" do
      should "validate issue" do
        response = @provider.validate_new_issue({project_id: 1, tracker_id: 1, status_id: 1, subject: "test issue", description: "test description"})
        assert response.is_success?
        assert response.value[:issue_id].nil?
      end

      should "return error with invalid project" do
        response = @provider.validate_new_issue({project_id: 1, tracker_id: 999, status_id: 1, subject: "test issue", description: "test description"})
        assert response.is_error?
        assert response.error.include?("Validation failed")
        assert response.error.include?("Tracker")
      end
    end

    context "validate_update_issue" do
      should "validate issue" do
        issue = Issue.find(1)
        original_subject = issue.subject
        response = @provider.validate_update_issue(issue_id: 1, subject: "test issue")
        assert response.is_success?
        assert_equal original_subject, Issue.find(issue.id).subject
      end

      should "return error with invalid issue" do
        response = @provider.validate_update_issue(issue_id: 999, subject: "test issue")
        assert response.is_error?
        assert response.error.include?("Issue not found")
      end
    end
  end
end
