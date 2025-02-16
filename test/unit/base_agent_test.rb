require File.expand_path("../../test_helper", __FILE__)
require "redmine_ai_helper/base_agent"

class BaseAgentTest < ActiveSupport::TestCase
  context "BaseAgent" do
    setup do
      @openai_mock = OpenAI::DummyOpenAIClient.new
      OpenAI::Client.stubs(:new).returns(@openai_mock)
      @params = {
        access_token: "test_access_token",
        uri_base: "http://example.com",
        organization_id: "test_org_id",
        model: "test_model",
      }
      @agent = MyAgent.new(@params)
      @messages = [{ role: "user", content: "Hello" }]
    end

    should "return available tool providers" do
      assert_equal ["dummy_tool_provider"], @agent.available_tool_providers
    end

    should "return correct role" do
      assert_equal "my_agent", @agent.role
    end

    should "return correct system prompt" do
      system_prompt = @agent.system_prompt
      assert_equal "system", system_prompt[:role]
      assert system_prompt[:content].include?("あなたのロールは my_agent です")
      assert system_prompt[:content].include?(@agent.backstory)
    end

    should "return available tools" do
      assert_equal "dummy_tool_provider", @agent.available_tools[:providers].first[:name]
    end

    should "return chat response as string" do
      response = @agent.chat(@messages)
      assert response.is_a?(String)
    end

    should "perform task successfully" do
      result = @agent.perform_task(@messages)
      assert_equal "merged result", result
    end

    should "merge results correctly" do
      pre_tasks = [{ "name" => "step1", "step" => "do something", "result" => "result1" }]
      result = @agent.merge_results(@messages, pre_tasks)
      assert_equal "merged result", result
    end

    should "decompose task correctly" do
      result = @agent.decompose_task(@messages)
      assert_equal [{ "name" => "step1", "step" => "do something" }], result["steps"]
    end

    should "dispatch task successfully" do
      result = @agent.dispatch("dispatch_success_test", @messages)
      assert result.is_success?
      assert_equal 1, result.value[:id]
    end

    should "handle dispatch error" do
      result = @agent.dispatch("dispatch_error", @messages)
      assert result.is_error?
    end

    should "select tool correctly" do
      result = @agent.select_tool("test task", @messages)
      assert_equal "project_tool_provider", result["tool"]["provider"]
      assert_equal "read_project", result["tool"]["tool"]
      assert_equal ["1"], result["tool"]["arguments"]["id"]
    end

    should "handle tool selection with pre error" do
      pre_tasks = [{ "name" => "step1", "step" => "do something", "result" => "result1" }]
      result = @agent.select_tool("test task", @messages, pre_tasks, "error")
      assert_equal "project_tool_provider", result["tool"]["provider"]
      assert_equal "read_project", result["tool"]["tool"]
      assert_equal ["1"], result["tool"]["arguments"]["id"]
    end

    should "handle tool selection with error handling" do
      pre_tasks = [{ "name" => "step1", "step" => "do something", "result" => "result1" }]
      result = @agent.select_tool("error_task", @messages, pre_tasks, "error")
      assert_equal "project_tool_provider", result["tool"]["provider"]
      assert_equal "read_project", result["tool"]["tool"]
      assert_equal ["1"], result["tool"]["arguments"]["id"]
    end
  end
end

module OpenAI
  class DummyOpenAIClient
    def chat(params = {})
      proc = params[:parameters][:stream]
      messages = params[:parameters][:messages]
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
      elsif message.include?("タスクを解決するために必要なステップに分解してください。")
        answer = { "steps" => [{ "name" => "step1", "step" => "do something" }] }.to_json
      else
        #puts "DummyOpenAIClient#chat params = #{message} called!!!!!!!!!!!!!!!!"
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

class MyAgent < RedmineAiHelper::BaseAgent
  def available_tool_providers
    ["dummy_tool_provider"]
  end

  def backstory
    "test_backstory"
  end
end

class DummyToolProvider < RedmineAiHelper::BaseToolProvider
  def self.list_tools
    list = {
      tools: [
        { name: "tool1",
          description: "tool1 description",
          arguments: { arg1: "arg1" } },
      ],

    }
    list
  end
end
