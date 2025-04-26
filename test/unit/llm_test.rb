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
    @openai_mock = DummyOpenAIClientForLlmTest.new
    Langchain::LLM::OpenAI.stubs(:new).returns(@openai_mock)
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
    message = AiHelperMessage.new(content: "hello", role: "user")
    @conversation.messages << message
    response = @llm.chat(@conversation, nil, { controller_name: "issues", action_name: "show", content_id: 1 })
    assert_equal "assistant", response.role
  end

  private

  def chat_answer_generator(message)
    { "choices": [{ "message": { "content": message } }] }
  end

  class DummyOpenAIClientForLlmTest < Langchain::LLM::OpenAI
    def initialize(params = {})
      super(api_key: "aaaa")
    end

    def chat_answer(message)
      { "choices": [{ "message": { "content": message } }] }
    end

    # Dummy implementation of the chat_answer method

    def chat_answer(message)
      { "choices": [{ "message": { "content": message } }] }
    end

    # Dummy implementation of the chat method
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
      else
        #puts "DummyOpenAIClient#chat params = #{message} called!!!!!!!!!!!!!!!!"
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
