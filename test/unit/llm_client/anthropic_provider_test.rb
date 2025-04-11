require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/llm_client/anthropic_provider"

class RedmineAiHelper::LlmClient::AnthropicProviderTest < ActiveSupport::TestCase
  context "AnthropicProvider" do
    setup do
      @provider = RedmineAiHelper::LlmClient::AnthropicProvider.new
    end

    should "generate a valid client" do
      Langchain::LLM::Anthropic.stubs(:new).returns(mock("AnthropicClient"))
      client = @provider.generate_client
      assert_not_nil client
    end

    should "raise an error if client generation fails" do
      Langchain::LLM::Anthropic.stubs(:new).returns(nil)
      assert_raises(RuntimeError, "Anthropic LLM Create Error") do
        @provider.generate_client
      end
    end

    should "create valid chat parameters" do
      system_prompt = { role: "system", content: "This is a system prompt" }
      messages = [{ role: "user", content: "Hello" }]
      chat_params = @provider.create_chat_param(system_prompt, messages)

      assert_equal messages, chat_params[:messages]
      assert_equal "This is a system prompt", chat_params[:system]
    end

    should "convert chunk correctly" do
      chunk = { "delta" => { "text" => "Test content" } }
      result = @provider.chunk_converter(chunk)
      assert_equal "Test content", result
    end

    should "return nil if chunk content is missing" do
      chunk = { "delta" => {} }
      result = @provider.chunk_converter(chunk)
      assert_nil result
    end

    should "reset assistant messages correctly" do
      assistant = mock("Assistant")
      assistant.expects(:clear_messages!).once
      assistant.expects(:instructions=).with("System instructions").once
      assistant.expects(:add_message).with(role: "user", content: "Hello").once

      system_prompt = "System instructions"
      messages = [{ role: "user", content: "Hello" }]

      @provider.reset_assistant_messages(
        assistant: assistant,
        system_prompt: system_prompt,
        messages: messages,
      )
    end
  end
end
