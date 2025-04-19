require File.expand_path("../../../test_helper", __FILE__)

class IssueSearchToolsTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields

  def setup
    @provider = RedmineAiHelper::Tools::IssueSearchTools.new
  end

  context "generate_url" do
    should "generate url with filters" do
      project = Project.find(1)
      response = @provider.generate_url(project_id: 1, fields: [{ field_name: "tracker_id", operator: "=", values: ["1"] }])
      assert_match "/projects/#{project.identifier}/issues?set_filter=1", response[:url]
    end

    should "generate url with no filters" do
      project = Project.find(1)
      response = @provider.generate_url(project_id: 1)
      assert_equal "/projects/#{project.identifier}/issues", response[:url]
    end

    should "generate url with date fields" do
      response = @provider.generate_url(project_id: 1, date_fields: [{ field_name: "created_on", operator: ">=", values: ["2020-01-01"] }])
      url_value = CGI.unescape(response[:url])
      assert url_value.include?("f[]=created_on")
      assert url_value.include?("op[created_on]=>")
      assert url_value.include?("v[created_on][]=2020-01-01")
    end

    should "generate url with time fields" do
      response = @provider.generate_url(project_id: 1, time_fields: [{ field_name: "estimated_hours", operator: "=", values: ["6"] }])
      url_value = CGI.unescape(response[:url])
      assert url_value.include?("f[]=estimated_hours")
      assert url_value.include?("op[estimated_hours]==")
      assert url_value.include?("v[estimated_hours][]=6")
    end

    should "generate url with number fields" do
      response = @provider.generate_url(project_id: 1, number_fields: [{ field_name: "done_ratio", operator: "=", values: ["6"] }])
      url_value = CGI.unescape(response[:url])
      assert url_value.include?("f[]=done_ratio")
      assert url_value.include?("op[done_ratio]==")
      assert url_value.include?("v[done_ratio][]=6")
    end

    should "generate url with text fields" do
      response = @provider.generate_url(project_id: 1, text_fields: [{ field_name: "subject", operator: "~", value: ["test"] }])
      url_value = CGI.unescape(response[:url])
      assert url_value.include?("f[]=subject")
      assert url_value.include?("op[subject]=~")
      # TODO: Fix this test
      # assert url_value.include?("v[subject][]=test")
    end

    should "generate url with status fields" do
      response = @provider.generate_url(project_id: 1, status_field: [{ field_name: "status_id", operator: "=", values: [1] }])
      url_value = CGI.unescape(response[:url])
      assert url_value.include?("f[]=status_id")
      assert url_value.include?("op[status_id]==")
      assert url_value.include?("v[status_id][]=1")
    end

    should "generate url with custom field" do
      response = @provider.generate_url(project_id: 1, custom_fields: [{ field_id: 1, operator: "=", values: ["MySQL"] }])
      url_value = CGI.unescape(response[:url])
      assert url_value.include?("f[]=cf_1")
      assert url_value.include?("op[cf_1]==")
      assert url_value.include?("v[cf_1][]=MySQL")
    end
  end
end
