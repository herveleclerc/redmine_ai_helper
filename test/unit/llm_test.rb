require File.expand_path("../../test_helper", __FILE__)
require "redmine_ai_helper/llm"

class RedmineAiHelper::LlmTest < ActiveSupport::TestCase
  def setup
    @params = {
      access_token: "test_access_token",
      uri_base: "http://example.com",
      organization_id: "test_org_id",
    }
    @openai_mock = DummyOpenAIClient.new
    OpenAI::Client.stubs(:new).returns(@openai_mock)
    @llm = RedmineAiHelper::Llm.new(@params)
    @conversation = AiHelperConversation.new(title: "test task")
    message = AiHelperMessage.new(content: "test task", role: "user")
    @conversation.messages << message
    # @conversation.stubs(:messages).returns([mock("message", role: "user", content: "test task")])
    # @openai_mock = mock("OpenAI::Client")
    # @openai_mock.stubs(:chat).returns({ "choices" => [{ "text" => "test answer" }] })

  end

  # def test_initialize
  #   assert_equal "test_access_token", @llm.instance_variable_get(:@client).access_token
  #   assert_equal "http://example.com", @llm.instance_variable_get(:@client).uri_base
  #   assert_equal "test_org_id", @llm.instance_variable_get(:@client).organization_id
  # end

  def test_chat_success
    # @openai_mock.stubs(:chat).returns(chat_answer_generator("test answer"))
    response = @llm.chat(@conversation, { controller_name: "issues", action_name: "show", content_id: 1 })
    assert_equal "assistant", response.role
    assert_equal "merged result", response.content
  end

  def test_chat_error
    # @openai_mock.stubs(:chat).returns(chat_answer_generator("test error"))
    response = @llm.chat(@conversation, { controller_name: "issues", action_name: "show", content_id: 1 })
    assert_equal "assistant", response.role
    assert_equal "test error", response.content
  end

  def test_execute_task_success
    # @openai_mock.stubs(:chat).returns({ "choices": { "steps" => [{ "name" => "step1", "step" => "do something" }] }.to_json })
    # @llm.stubs(:dispatch).returns(TaskResponse.create_success("step result"))
    result = @llm.execute_task("test task", @conversation)
    assert_equal "success", result[:status]
    assert_equal "merged result", result[:answer]
  end

  def test_execute_task_error
    # answer = { "steps" => [{ "name" => "step1", "step" => "do something" }] }.to_json
    # @openai_mock.stubs(:chat).returns(chat_answer_generator(answer))
    # @llm.stubs(:dispatch).returns(TaskResponse.create_error("step error"))
    result = @llm.execute_task("test task", @conversation)
    assert_equal "error", result[:status]
    assert_equal "Failed to decompose the task", result[:error]
  end

  def test_merge_results
    pre_tasks = [{ "name" => "step1", "step" => "do something", "result" => "result1" }]
    # @openai_mock.stubs(:chat).returns(chat_answer_generator("merged result"))
    result = @llm.merge_results("merge_results_test", @conversation, pre_tasks)
    assert_equal "merged result ok", result
  end

  def test_decompose_task
    # answer = { "steps" => [{ "name" => "step1", "step" => "do something" }] }.to_json
    # @openai_mock.stubs(:chat).returns(chat_answer_generator(answer))
    result = @llm.decompose_task("test task", @conversation)
    assert_equal [{ "name" => "step1", "step" => "do something" }], result["steps"]
  end

  def test_simple_llm_chat
    # @openai_mock.stubs(:chat).returns(chat_answer_generator("chat result"))

    response = @llm.simple_llm_chat(@conversation)
    assert_equal "test answer", response.value
  end

  def test_dispatch_success
    # answer = { "tool" => { "agent" => "project_agent", "tool" => "read_project", "arguments" => { "project_id": ["1"] } } }.to_json
    # @openai_mock.stubs(:chat).returns(chat_answer_generator(answer))
    result = @llm.dispatch("dispatch_success_test", @conversation)
    assert_equal "tool result", result.value
  end

  def test_dispatch_error
    # @llm.stubs(:select_tool).returns({ "tool" => { "agent" => "test_agent", "tool" => "test_tool", "arguments" => {} } })
    agent = mock("agent")
    # agent.stubs(:call_tool).raises(StandardError.new("tool error"))
    # RedmineAiHelper::Agent.stubs(:new).returns(agent)
    result = @llm.dispatch("test task", @conversation)
    assert_equal "tool error", result.error
  end

  def test_select_tool
    # @llm.stubs(:chat_wrapper).returns('{"tool":{"agent":"test_agent","tool":"test_tool","arguments":{"id":1}}}')
    result = @llm.select_tool("test task", @conversation)
    assert_equal "test_agent", result["tool"]["agent"]
    assert_equal "test_tool", result["tool"]["tool"]
    assert_equal 1, result["tool"]["arguments"]["id"]
  end

  private

  def chat_answer_generator(message)
    { "choices": [{ "message": { "content": message } }] }
  end

  class DummyOpenAIClient
    def chat(params = {})
      messages = params[:parameters][:messages]
      message = messages.last[:content]

      answer = "test answer"
      if message.include?("というタスクを解決するのに最適なツールを")
        answer = { "tool" => { "agent" => "project_agent", "tool" => "read_project", "arguments" => { "project_id": ["1"] } } }.to_json
      elsif message.include?("というタスクを解決するために必要なステップに分解してください。")
        answer = { "steps" => [{ "name" => "step1", "step" => "do something" }] }.to_json
      elsif message.include?("タスクに対する最終回答を作成してください")
        puts message
        answer = "merged result"
        if message.include?("merge_results_test")
          answer = "merged result ok"
        end
      else
        puts "DummyOpenAIClient#chat prams = #{message} called!!!!!!!!!!!!!!!!"
      end

      response = { "choices": [{ "message": { "content": answer } }] }.deep_stringify_keys
      puts answer
      response
    end
  end
end
