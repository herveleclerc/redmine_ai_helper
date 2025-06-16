require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/agents/issue_agent"

class RedmineAiHelper::Agents::IssueAgentTest < ActiveSupport::TestCase
  fixtures :projects, :users, :issues, :issue_statuses, :trackers, :enumerations

  context "IssueAgent" do
    setup do
      @project = Project.find(1)
      @user = User.find(1)
      @issue = Issue.find(1)
      @langfuse = RedmineAiHelper::LangfuseUtil::LangfuseWrapper.new(input: "Test input for Langfuse")
      @agent = RedmineAiHelper::Agents::IssueAgent.new(project: @project, langfuse: @langfuse)
    end

    should "generate backstory including issue properties" do
      backstory = @agent.backstory
      assert_match /issue properties are available/, backstory
      assert_match /Project ID: #{@project.id}/, backstory
    end

    should "include vector tools when vector db is enabled" do
      AiHelperSetting.any_instance.stubs(:vector_search_enabled).returns(true)
      tools = @agent.available_tool_providers
      assert_includes tools, RedmineAiHelper::Tools::VectorTools
      assert_includes tools, RedmineAiHelper::Tools::IssueTools
      assert_includes tools, RedmineAiHelper::Tools::ProjectTools
    end

    should "not include vector tools when vector db is disabled" do
      AiHelperSetting.any_instance.stubs(:vector_search_enabled).returns(false)
      tools = @agent.available_tool_providers
      assert_not_includes tools, RedmineAiHelper::Tools::VectorTools
      assert_includes tools, RedmineAiHelper::Tools::IssueTools
      assert_includes tools, RedmineAiHelper::Tools::ProjectTools
    end

    should "generate issue summary for visible issue" do
      @issue.stubs(:visible?).returns(true)

      # モックプロンプトを設定
      mock_prompt = mock("Prompt")
      mock_prompt.stubs(:format).returns("Summarize this issue")
      @agent.stubs(:load_prompt).with("issue_agent/summary").returns(mock_prompt)

      # chatメソッドをモック
      @agent.stubs(:chat).returns("This is a summary of the issue.")

      result = @agent.issue_summary(issue: @issue)
      assert_equal "This is a summary of the issue.", result
    end

    should "deny access for non-visible issue" do
      @issue.stubs(:visible?).returns(false)
      result = @agent.issue_summary(issue: @issue)
      assert_equal "Permission denied", result
    end

    should "generate issue properties string" do
      RedmineAiHelper::Tools::IssueTools.any_instance.stubs(:capable_issue_properties).returns({
        "priority" => ["High", "Normal", "Low"],
        "status" => ["New", "In Progress", "Resolved"],
      })

      issue_properties = @agent.send(:issue_properties)

      assert_match /The following issue properties are available/, issue_properties
      assert_match /Project ID: #{@project.id}/, issue_properties
      assert_match /"priority"/, issue_properties
      assert_match /"status"/, issue_properties
    end

    context "generate_issue_reply" do
      should "generate reply for visible issue" do
        @issue.stubs(:visible?).returns(true)

        # モックプロンプトを設定
        mock_prompt = mock("Prompt")
        mock_prompt.stubs(:format).returns("Generate a reply for this issue")
        @agent.stubs(:load_prompt).with("issue_agent/generate_reply").returns(mock_prompt)

        # chatメソッドをモック
        @agent.stubs(:chat).returns("This is a generated reply.")

        result = @agent.generate_issue_reply(issue: @issue, instructions: "Please provide a detailed response.")
        assert_equal "This is a generated reply.", result
      end

      should "deny access for non-visible issue" do
        @issue.stubs(:visible?).returns(false)
        result = @agent.generate_issue_reply(issue: @issue, instructions: "Please provide a detailed response.")
        assert_equal "Permission denied", result
      end
      should "format instructions correctly in the prompt" do
        @issue.stubs(:visible?).returns(true)
        setting = AiHelperProjectSetting.settings(@issue.project)
        setting.issue_draft_instructions = "Draft instructions for the issue."
        setting.save!
        mock_prompt = mock("Prompt")
        mock_prompt.expects(:format).with(
          issue: instance_of(String),
          instructions: "Please provide a detailed response.",
          issue_draft_instructions: "Draft instructions for the issue.",
          format: Setting.text_formatting,
        ).returns("Generate a reply for this issue with instructions.")
        @agent.stubs(:load_prompt).with("issue_agent/generate_reply").returns(mock_prompt)

        @agent.stubs(:chat).returns("This is a generated reply.")

        result = @agent.generate_issue_reply(issue: @issue, instructions: "Please provide a detailed response.")
        assert_equal "This is a generated reply.", result
      end
    end

    context "generate_sub_issues_draft" do
      setup do
        Langchain::OutputParsers::OutputFixingParser.stubs(:from_llm).returns(DummyFixParser.new)

        @agent.stubs(:chat).returns("This is a generated reply.")
        User.current = User.find(1)
      end
      should "generate sub issues for visible issue" do
        issue = Issue.find(1)

        subissues = @agent.generate_sub_issues_draft(issue: issue, instructions: "Create sub issues based on this issue.")

        assert subissues
      end
    end
  end

  class DummyFixParser
    def parse(text)
      { "sub_issues" => [{ "subject" => "Dummy Sub Issue", "description" => "This is a dummy sub issue description." }] }
    end

    def get_format
      # フォーマットは単純な文字列とする
      "string"
    end
  end
end
