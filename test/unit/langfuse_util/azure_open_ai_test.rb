require File.expand_path("../../../test_helper", __FILE__)

class RedmineAiHelper::LangfuseUtil::AzureOpenAiTest < ActiveSupport::TestCase
  setup do
    # Save original :chat method if defined

    Langchain::LLM::Azure.class_eval do
      alias_method :__original_chat, :chat
    end

    Langchain::LLM::Azure.class_eval do
      define_method(:chat) do |*args, **kwargs|
        # Stubbed parent result for testing
        DummyResponse.new
      end
    end
    @client = RedmineAiHelper::LangfuseUtil::AzureOpenAi.new(
      api_key: "test_key",
    )
    langfuse = RedmineAiHelper::LangfuseUtil::LangfuseWrapper.new(input: "test")
    langfuse.stubs(:enabled?).returns(true)
    @client.langfuse = langfuse
    @client.langfuse.create_span(name: "test_span", input: "test_input")
  end

  teardown do
    Langchain::LLM::Azure.class_eval do
      remove_method :chat
      alias_method :chat, :__original_chat
      remove_method :__original_chat
    end
  end

  context "chat" do
    should "create an observation with correct parameters" do
      messages = [{ role: "user", content: "Test input" }]

      answer = @client.chat(messages: messages, model: "gemini-1.0", temperature: 0.5)
      assert answer
    end

    should "work without langfuse" do
      @client.langfuse = nil
      messages = [{ role: "user", content: "Test input" }]

      answer = @client.chat(messages: messages, model: "gpt-4", temperature: 0.5)
      assert answer
    end

    should "work without current_span" do
      @client.langfuse.stubs(:current_span).returns(nil)
      messages = [{ role: "user", content: "Test input" }]

      answer = @client.chat(messages: messages, model: "gpt-4", temperature: 0.5)
      assert answer
    end
  end

  class DummyResponse
    def chat_completion(*args)
      { "choices" => [{ "message" => { "content" => "answer" } }] }
    end

    def prompt_tokens
      10
    end

    def completion_tokens
      5
    end

    def total_tokens
      prompt_tokens + completion_tokens
    end
  end

  class DummyHttp
    attr_accessor :use_ssl, :read_timeout, :open_timeout

    def request(*args)
      return Response.new
    end

    class Response
      def body
        json = { "choices" => [{ "message" => { "content" => "answer" } }] }
        JSON.pretty_generate(json)
      end

      def code
        "200"
      end
    end
  end
end
