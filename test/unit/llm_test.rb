require File.expand_path("../../test_helper", __FILE__)
require "redmine_ai_helper/llm"

class RedmineAiHelper::LlmTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :custom_values, :groups_users, :members, :member_roles, :roles, :user_preferences

  context "RedmineAiHelper::Llm" do
    setup do
      AiHelperConversation.delete_all
      @params = {
        access_token: "test_access_token",
        uri_base: "http://example.com",
        organization_id: "test_org_id",
      }
      @openai_mock = DummyOpenAIClientForLlmTest.new
      Langchain::LLM::OpenAI.stubs(:new).returns(@openai_mock)
      @llm = RedmineAiHelper::Llm.new(@params)
      @conversation = AiHelperConversation.new(title: "test task")
      message = AiHelperMessage.new(content: "test task", role: "user")
      @conversation.messages << message
    end

    should "respond with assistant role on chat success" do
      message = AiHelperMessage.new(content: "hello", role: "user")
      @conversation.messages << message
      response = @llm.chat(@conversation, nil, { controller_name: "issues", action_name: "show", content_id: 1 })
      assert_equal "assistant", response.role
    end

    context "issue summary" do
      setup do
        @issue = Issue.find(1)
        @llm = RedmineAiHelper::Llm.new(@params)
      end

      should "deny access for non-visible issue" do
        @issue.stubs(:visible?).returns(false)
        summary = @llm.issue_summary(issue: @issue)
        assert_equal "Permission denied", summary
      end
    end

    context "generate_issue_reply" do
      setup do
        @issue = Issue.find(1)
        @llm = RedmineAiHelper::Llm.new(@params)
      end

      should "deny access for non-visible issue" do
        @issue.stubs(:visible?).returns(false)
        reply = @llm.generate_issue_reply(issue: @issue, instructions: "test instructions")
        assert_equal "Permission denied", reply
      end

      should "generate reply for visible issue" do
        @issue.stubs(:visible?).returns(true)
        RedmineAiHelper::Agents::IssueAgent.any_instance.stubs(:generate_issue_reply).returns("Generated reply")
        reply = @llm.generate_issue_reply(issue: @issue, instructions: "test instructions")
        assert_equal "Generated reply", reply
      end
    end

    context "generate_sub_issues" do
      setup do
        @issue = Issue.find(1)
        @llm = RedmineAiHelper::Llm.new(@params)
        RedmineAiHelper::Agents::IssueAgent.stubs(:new).returns(DummyIssueAgent.new)
      end

      should "deny access for non-visible issue" do
        @issue.stubs(:visible?).returns(false)
        sub_issues = @llm.generate_sub_issues(issue: @issue, instructions: "test instructions")
        assert_equal "Permission denied", sub_issues
      end

      should "generate sub issues for visible issue" do
        @issue.stubs(:visible?).returns(true)
        RedmineAiHelper::Agents::IssueAgent.any_instance.stubs(:generate_sub_issues).returns([Issue.new(subject: "Sub issue 1"), Issue.new(subject: "Sub issue 2")])
        sub_issues = @llm.generate_sub_issues(issue: @issue, instructions: "test instructions")
        assert_equal 2, sub_issues.length
        assert_equal "Sub issue 1", sub_issues[0].subject
      end
    end
  end

  private

  def chat_answer_generator(message)
    { "choices": [{ "message": { "content": message } }] }
  end

  class DummyOpenAIClientForLlmTest < Langchain::LLM::OpenAI
    attr_accessor :langfuse

    def initialize(params = {})
      super(api_key: "aaaa")
    end

    def chat_answer(message)
      { "choices": [{ "message": { "content": message } }] }
    end

    def chat(params = {})
      messages = params[:messages]
      message = messages.last[:content]

      answer = "test answer"
      if message.include?("タスクに対する最終回答を作成してください")
        answer = "merged result"
        if message.include?("merge_results_test")
          answer = "merged result ok"
        end
      elsif message.include?("というタスクを解決するのに最適なツールを")
        answer = { "tool" => { "provider" => "project_tool_provider", "tool" => "read_project", "arguments" => { "id": ["1"] } } }.to_json
        if message.include?("dispatch_success_test")
          answer = { "tool" => { "provider" => "project_tool_provider", "tool" => "read_project", "arguments" => { "id": ["1"] } } }.to_json
        elsif message.include?("execute_task_error")
          answer = { "tool" => { "provider" => "project_tool_provider", "tool" => "read_project", "arguments" => { "id": ["999"] } } }.to_json
        elsif message.include?("dispatch_error")
          answer = { "tool" => { "provider" => "aaaa", "tool" => "read_project", "arguments" => { "id": ["999"] } } }.to_json
        end
      elsif message.include?("provide step-by-step instructions")
        answer = { "steps" => [{ "name" => "step1", "step" => "do something" }] }.to_json
      elsif message.include?("To achieve the goal of")
        answer = {
          "steps": [
            { "agent": "leader", "step": "my_projectという名前のプロジェクトのIDを教えてください" },
          ],
        }.to_json
      end

      if block_given?
        chunk = {
          "index": 0,
          "delta": { "content": answer },
          "finish_reason": nil,
        }.deep_stringify_keys
        yield(chunk)
      end

      response = { "choices": [{ "message": { "content": answer } }] }.deep_stringify_keys
      response
    end
  end

  class DummyIssueAgent
    def generate_sub_issues_draft(args = {})
      return "Permission denied" unless args[:issue].visible?
      [
        Issue.new(subject: "Sub issue 1", tracker_id: 1, project_id: 1),
        Issue.new(subject: "Sub issue 2", tracker_id: 1, project_id: 1),
      ]
    end
  end
end
