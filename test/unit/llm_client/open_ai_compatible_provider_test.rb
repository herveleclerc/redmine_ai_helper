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
      ::OpenAI::Client.stubs(:new).returns(@openai_mock)
      # Langchain::LLM::OpenAI.stubs(:new).returns(@openai_mock)
      @client = RedmineAiHelper::LlmClient::OpenAiCompatibleProvider::OpenAiCompatible.new(
        api_key: "test_key",
      )
    end

    should "return a valid response for chat" do
      params = {
        messages: [{ role: "user", content: "Hello" }],
      }
      response = @client.chat(params).chat_completion
      assert_not_nil response
      assert_equal response, "This is a dummy response for testing."
    end
  end

  context "OpenAiCompatible" do
    setup do
      @openai_mock = OpenAiCompatibleTest::DummyOpenAIClient.new
      ::OpenAI::Client.stubs(:new).returns(@openai_mock)
      @openai = RedmineAiHelper::LlmClient::OpenAiCompatibleProvider::OpenAiCompatible.new(
        api_key: "test_key",
        llm_options: { uri_base: "https://api.example.com" },
      )
    end

    context "select_tools" do
      should "return a response with tool calls" do
        messages = [
          { role: "user", content: "ユーザーが達成したい目的を明確にし、プロジェクトの目標を設定するために" },
        ]
        tools = []
        response = @openai.select_tools(messages: messages, tools: tools)
        assert response.tool_calls
      end
    end

    context "select_tool_result" do
      should "return a response with tool call results" do
        messages = [
          { role: "user", content: "What is the weather in Tokyo on 2023-10-01?" },
          { role: "assistant", content: "Please use the weather tool." },
          {
            role: "assistant",
            tool_calls: [
              {
                id: "call_rCE6Kk94VZZyUIrIlrZSH0Cr",
                type: "function",
                function: {
                  name: "weather_tool__weather",
                  arguments: "{\"location\": \"Tokyo\", \"date\": \"2023-10-01\"}",
                },
              },
            ],
          },
          {
            role: "tool",
            name: "weather_tool__weather",
            content: {
              location: "Tokyo",
              date: "2023-10-01",
            },
          },
        ]
        response = @openai.send_tool_result(messages: messages)
        assert response.tool_calls
      end
    end
  end
end

module OpenAiCompatibleTest
  class DummyOpenAIClient
    def chat(params = {}, &block)
      messages = params[:parameters][:messages] || []
      # puts "Messages: #{messages.inspect}"
      message = messages.first[:content]
      # puts "Message content: #{message}"

      json_content = {
        tool_calls: [
          {
            id: "call_rCE6Kk94VZZyUIrIlrZSH0Cr",
            type: "function",
            function: {
              name: "weather_tool__weather",
              arguments: "{\"location\": \"Tokyo\", \"date\": \"2023-10-01\"}",
            },
          },
        ],
      }
      content = JSON.pretty_generate(json_content)

      if message == "Hello"
        content = "This is a dummy response for testing."
      end

      response = {
        "choices" => [
          {
            "message" => {
              "role" => "assistant",
              "content" => content,
            },
          },
        ],
      }
      block.call(response) if block_given?
      response
    end
  end
end
