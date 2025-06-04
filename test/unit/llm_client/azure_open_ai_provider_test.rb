require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/llm_client/open_ai_compatible_provider"

class RedmineAiHelper::LlmClient::AzureOpenAiProviderTest < ActiveSupport::TestCase
  context "AzureOpenAiProvider" do
    setup do
      @setting = AiHelperSetting.find_or_create
      @openai_mock = AzureOpenAiProviderTest::DummyOpenAIClient.new
      Langchain::LLM::OpenAI.stubs(:new).returns(@openai_mock)
      @provider = RedmineAiHelper::LlmClient::AzureOpenAiProvider.new

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
    end
  end
end

module AzureOpenAiProviderTest
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
