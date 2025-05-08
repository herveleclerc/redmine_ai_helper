require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/llm_client/base_provider"

class RedmineAiHelper::LlmClient::BaseProviderTest < ActiveSupport::TestCase
  context "BaseProvider" do
    setup do
      @provider = RedmineAiHelper::LlmClient::BaseProvider.new
    end

    should "raise NotImplementedError when generate_client is called" do
      assert_raises(NotImplementedError, "LLM provider not found") do
        @provider.generate_client
      end
    end

    should "create chat parameters correctly" do
      system_prompt = { content: "This is a system prompt" }
      messages = [
        { role: "user", content: "Hello" },
        { role: "assistant", content: "Hi there!" },
      ]
      chat_params = @provider.create_chat_param(system_prompt, messages)

      assert_equal 3, chat_params[:messages].size
      assert_equal "This is a system prompt", chat_params[:messages][0][:content]
      assert_equal "Hello", chat_params[:messages][1][:content]
      assert_equal "Hi there!", chat_params[:messages][2][:content]
    end

    should "convert chunk correctly" do
      chunk = { "delta" => { "content" => "Test content" } }
      result = @provider.chunk_converter(chunk)
      assert_equal "Test content", result
    end

    should "return nil if chunk content is missing" do
      chunk = { "delta" => {} }
      result = @provider.chunk_converter(chunk)
      assert_nil result
    end

    should "reset assistant messages correctly" do
      mock_assistant = mock("Assistant")
      mock_assistant.expects(:clear_messages!).once
      mock_assistant.expects(:add_message).with(role: "system", content: "System instructions").once
      mock_assistant.expects(:add_message).with(role: "user", content: "Hello").once
      mock_assistant.expects(:add_message).with(role: "assistant", content: "Hi there!").once

      system_prompt = { content: "System instructions" }
      messages = [
        { role: "user", content: "Hello" },
        { role: "assistant", content: "Hi there!" },
      ]

      @provider.reset_assistant_messages(
        assistant: mock_assistant,
        system_prompt: system_prompt,
        messages: messages,
      )
    end
  end
end
