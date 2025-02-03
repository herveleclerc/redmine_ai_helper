require File.expand_path("../../test_helper", __FILE__)
require "redmine_ai_helper/llm"

class RedmineAiHelper::LlmTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :custom_values, :groups_users, :members, :member_roles, :roles, :user_preferences
  def setup
    AiHelperConversation.delete_all
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


  end

  # def test_initialize
  #   assert_equal "test_access_token", @llm.instance_variable_get(:@client).access_token
  #   assert_equal "http://example.com", @llm.instance_variable_get(:@client).uri_base
  #   assert_equal "test_org_id", @llm.instance_variable_get(:@client).organization_id
  # end

  def test_chat_success
    message = AiHelperMessage.new(content: "test task", role: "user")
    @conversation.messages << message
    response = @llm.chat(@conversation, { controller_name: "issues", action_name: "show", content_id: 1 })
    assert_equal "assistant", response.role
    assert_equal "merged result", response.content
  end

  def test_execute_task_success
    result = @llm.execute_task("test task", @conversation)
    assert_equal "success", result[:status]
    assert_equal "merged result", result[:answer]
  end


  def test_merge_results
    pre_tasks = [{ "name" => "step1", "step" => "do something", "result" => "result1" }]
    result = @llm.merge_results("merge_results_test", @conversation, pre_tasks)
    assert_equal "merged result ok", result
  end

  def test_decompose_task
    result = @llm.decompose_task("test task", @conversation)
    assert_equal [{ "name" => "step1", "step" => "do something" }], result["steps"]
  end

  def test_simple_llm_chat

    response = @llm.simple_llm_chat(@conversation)
    assert_equal "test answer", response.value
  end

  def test_dispatch_success

    result = @llm.dispatch("dispatch_success_test", @conversation)
    #puts "result = #{result}"
    assert result.is_success?
    assert_equal 1, result.value[:id]
  end

  def test_dispatch_error

    result = @llm.dispatch("dispatch_error", @conversation)
    assert result.is_error?
  end

  def test_select_tool
    result = @llm.select_tool("test task", @conversation)
    assert_equal "project_agent", result["tool"]["agent"]
    assert_equal "read_project", result["tool"]["tool"]
    assert_equal ["1"], result["tool"]["arguments"]["id"]
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
      if message.include?("タスクに対する最終回答を作成してください")
        #puts message
        answer = "merged result"
        if message.include?("merge_results_test")
          answer = "merged result ok"
        end
      elsif message.include?("というタスクを解決するのに最適なツールを")
        answer = { "tool" => { "agent" => "project_agent", "tool" => "read_project", "arguments" => { "id": ["1"] } } }.to_json
        if message.include?("execute_task_error")
          answer = { "tool" => { "agent" => "project_agent", "tool" => "read_project", "arguments" => { "id": ["999"] } } }.to_json
        elsif message.include?("dispatch_error")
          answer = { "tool" => { "agent" => "aaaa", "tool" => "read_project", "arguments" => { "id": ["999"] } } }.to_json
        end
        
      elsif message.include?("というタスクを解決するために必要なステップに分解してください。")
        answer = { "steps" => [{ "name" => "step1", "step" => "do something" }] }.to_json
      else
        #puts "DummyOpenAIClient#chat prams = #{message} called!!!!!!!!!!!!!!!!"
      end

      response = { "choices": [{ "message": { "content": answer } }] }.deep_stringify_keys
      #puts answer
      response
    end
  end
end
