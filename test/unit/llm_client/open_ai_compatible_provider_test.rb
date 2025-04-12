require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/llm_client/open_ai_compatible_provider"

class RedmineAiHelper::LlmClient::OpenAiCompatibleProviderTest < ActiveSupport::TestCase
  context "OpenAiCompatibleProvider" do
    setup do
      @openai_mock = OpenAiCompatibleTest::DummyOpenAIClient.new
      Langchain::LLM::OpenAI.stubs(:new).returns(@openai_mock)
      @provider = RedmineAiHelper::LlmClient::OpenAiCompatibleProvider.new

      @setting = AiHelperSetting.find_or_create
      @original_model_profile = @setting.model_profile
    end

    teardown do
      @setting.model_profile = @original_model_profile
      @setting.save!
    end

    should "generate a valid client" do
      client = @provider.generate_client
      assert_not_nil client
    end

    should "raise an error if model profile is missing" do
      @setting.model_profile = nil
      @setting.save!
      assert_raises(RuntimeError, "Model Profile not found") do
        @provider.generate_client
      end
    end

    should "raise an error if base URI is missing" do
      profile = AiHelperModelProfile.create!(
        name: "Test Profile aaaa",
        llm_type: "OpenAI",
        llm_model: "gpt-3.5-turbo",
        access_key: "test_key",
        organization_id: "test_org_id",
      )
      @setting.model_profile = profile
      @setting.save!
      assert_raises(RuntimeError, "Base URI not found") do
        @provider.generate_client
      end
    end
  end

  context "OpenAiCompatible" do
    setup do
      @openai_mock = OpenAiCompatibleTest::DummyOpenAIClient.new
      Langchain::LLM::OpenAI.stubs(:new).returns(@openai_mock)
      @client = RedmineAiHelper::LlmClient::OpenAiCompatibleProvider::OpenAiCompatible.new({})
    end

    should "return a valid response for chat" do
      params = {
        messages: [{ role: "user", content: "Hello" }],
      }
      response = @client.chat(params)
      assert_not_nil response
      assert response.is_a?(Hash)
      assert response.key?("choices")
    end
  end
end

module OpenAiCompatibleTest
  class DummyOpenAIClient < Langchain::LLM::OpenAI
    def initialize(params = {})
      super(api_key: "aaaa")
    end

    def chat(params = {})
      messages = params[:messages]
      message = messages.last[:content]

      answer = "test answer"

      if message.include?("ユーザーが達成したい目的を明確にし")
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
      elsif message.include?("というゴールを解決するために")
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
