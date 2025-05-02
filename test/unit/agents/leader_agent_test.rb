require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/agents/leader_agent"

class LeaderAgentTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields
  setup do
    @openai_mock = MyOpenAI::DummyOpenAIClient.new
    Langchain::LLM::OpenAI.stubs(:new).returns(@openai_mock)
    @params = {
      access_token: "test_access_token",
      uri_base: "http://example.com",
      organization_id: "test_org_id",
      model: "test_model",
      project: Project.find(1),
    }
    @agent = RedmineAiHelper::Agents::LeaderAgent.new(@params)
    @messages = [{ role: "user", content: "Hello" }]
  end
  context "LeaderAgent" do
    should "return correct role" do
      assert_equal "leader", @agent.role
    end

    should "return correct backstory" do
      backstory = @agent.backstory
      assert backstory.include?("あなたは RedmineAIHelper プラグインのリーダーエージェントです")
    end

    should "return correct system prompt" do
      system_prompt = @agent.system_prompt
      assert_equal "system", system_prompt[:role]
      assert system_prompt[:content].include?(@agent.backstory)
    end

    should "generate goal correctly" do
      goal = @agent.generate_goal(@messages)
      assert goal.is_a?(String)
      assert_equal "test goal", goal
    end

    should "generate steps correctly" do
      goal = "test goal"
      steps = @agent.generate_steps(goal, @messages)
      assert steps.is_a?(Hash)
      assert steps["steps"].is_a?(Array)
    end

    should "perform user request successfully" do
      result = @agent.perform_user_request(@messages)
      assert result.is_a?(String)
    end
  end
end

module MyOpenAI
  class DummyOpenAIClient < Langchain::LLM::OpenAI
    def initialize(params = {})
      super(api_key: "aaaa")
    end

    def chat(params = {})
      messages = params[:messages]
      message = messages.last[:content]

      answer = "test answer"

      if message.include?("Clearly define the goal the user wants to achieve")
        answer = "test goal"
      elsif message.include?("から与えられたタスクを解決するために")
        answer = {
          "steps": [
            {
              "name": "step1",
              "step": "チケットを更新するために、必要な情報を整理する。",
              "tool": {
                "provider": "issue_tool_provider",
                "tool_name": "capable_issue_properties",
              },
            },
            {
              "name": "step2",
              "step": "前のステップで取得したステータスを使用してチケットを更新する",
              "tool": {
                "provider": "issue_tool_provider",
                "tool_name": "update_issue",
              },
            },
          ],

        }.to_json
      elsif message.include?("To achieve the goal of")
        answer = {
          "steps": [
            { "agent": "project_agent", "step": "my_projectという名前のプロジェクトのIDを教えてください" },
            { "agent": "project_agent", "step": "my_projectの情報を取得してください" },
          ],
        }.to_json
      else
        answer = "test answer"
      end

      if block_given?
        { "index" => 0, "delta" => { "content" => "ら" }, "logprobs" => nil, "finish_reason" => nil }
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
end
