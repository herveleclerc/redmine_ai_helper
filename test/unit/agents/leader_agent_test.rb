require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/agents/leader_agent"

class LeaderAgentTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields
  context "LeaderAgent" do
    setup do
      @openai_mock = MyOpenAI::DummyOpenAIClient.new
      OpenAI::Client.stubs(:new).returns(@openai_mock)
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

    should "perform task successfully" do
      result = @agent.perform_task(@messages)
      assert result.is_a?(String)
    end
  end
end

module MyOpenAI
  class DummyOpenAIClient
    def chat(params = {})
      proc = params[:parameters][:stream]
      messages = params[:parameters][:messages]
      message = messages.last[:content]

      answer = "test answer"
      if message.include?("ユーザーが達成したい目的を明確にし")
        answer = "test goal"
      elsif message.include?("というゴールを解決するために")
        answer = {
          "steps": [
            { "agent": "leader", "step": "my_projectという名前のプロジェクトのIDを教えてください" },
          ]
        }.to_json
      else
        answer = "test answer"
      end

      chunk = {
        "id": "response_id",
        "object": "chat.completion.chunk",
        "created": Time.now.to_i,
        "model": "gpt-3.5-turbo-0613",
        "choices": [
          { "index": 0,
            "delta": { "content": answer },
            "finish_reason": nil },
        ],
      }.deep_stringify_keys

      proc.call(chunk, nil) if proc

      response = { "choices": [{ "message": { "content": answer } }] }.deep_stringify_keys
      response
    end
  end
end
