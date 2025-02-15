require File.expand_path("../../test_helper", __FILE__)
require "redmine_ai_helper/base_agent"

class BaseAgentTest < ActiveSupport::TestCase
  def setup
    @openai_mock = OpenAI::DummyOpenAIClient.new
    OpenAI::Client.stubs(:new).returns(@openai_mock)
    @room_id = 1
    @params = {
      access_token: "test_access_token",
      uri_base: "http://example.com",
      organization_id: "test_org_id",
      model: "test_model",
    }
    @agent = MyAgent.new(@room_id, @params)
  end

  def test_initialize
    assert_equal @room_id, @agent.instance_variable_get(:@room_id)
  end

  def test_available_tool_providers
    assert_equal [], @agent.available_tool_providers
  end

  def test_role
    assert_equal "my_agent", @agent.role
  end

  def test_system_prompt
    system_prompt = @agent.system_prompt
    assert_equal "system", system_prompt[:role]
    assert system_prompt[:content].include?("あなたのロールは my_agent です")
    assert system_prompt[:content].include?(@agent.backstory)
  end

  def test_available_tools
    assert_equal "dummy_tool_provider", @agent.available_tools[:providers].first[:name]
  end

  def test_chat
    messages = [{ role: "user", content: "Hello" }]
    option = {}

    response = @agent.chat(messages, option)
    assert response.is_a?(String)
  end

  def test_perform_task
    messages = [{ role: "user", content: "Hello" }]
    option = {}
    callback = proc { |content| puts content }
    assert_equal "test answer", @agent.perform_task(messages, option, callback)
  end

  def test_available_tool_providers
    agent = MyAgent.new(@room_id, @params)
    assert_equal ["dummy_tool_provider"], agent.available_tool_providers
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
      elsif message.include?("というタスクを解決するために必要なステップに分解してください。")
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
