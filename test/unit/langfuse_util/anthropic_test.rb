require File.expand_path("../../../test_helper", __FILE__)

class RedmineAiHelper::LangfuseUtil::AnthropicTest < ActiveSupport::TestCase
  setup do
    # Save original :chat method if defined

    Langchain::LLM::Anthropic.class_eval do
      alias_method :__original_chat, :chat
    end

    Langchain::LLM::Anthropic.class_eval do
      define_method(:chat) do |*args, **kwargs|
        # Stubbed parent result for testing
        DummyResponse.new
      end
    end
    @client = RedmineAiHelper::LangfuseUtil::Anthropic.new(
      api_key: "test_key",
    )
    langfuse = RedmineAiHelper::LangfuseUtil::LangfuseWrapper.new(input: "test")
    langfuse.stubs(:enabled?).returns(true)
    @client.langfuse = langfuse
    @client.langfuse.create_span(name: "test_span", input: "test_input")
    @client.langfuse.create_span(name: "test_span", input: "test_input")
  end

  teardown do
    Langchain::LLM::Anthropic.class_eval do
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

      answer = @client.chat(messages: messages, model: "claude-3", temperature: 0.5)
      assert answer
    end

    should "work without current_span" do
      @client.langfuse.stubs(:current_span).returns(nil)
      messages = [{ role: "user", content: "Test input" }]

      answer = @client.chat(messages: messages, model: "claude-3", temperature: 0.5)
      assert answer
    end

    should "include system message when provided" do
      mock_span = mock('span')
      mock_generation = mock('generation')
      @client.langfuse.stubs(:current_span).returns(mock_span)
      
      expected_messages = [
        { role: "system", content: "You are a helpful assistant" },
        { role: "user", content: "Hello" }
      ]
      
      mock_span.expects(:create_generation).with() do |params|
        params[:messages] == expected_messages &&
        params[:name] == "chat" &&
        params[:model] == "claude-3" &&
        params[:temperature] == 0.7
      end.returns(mock_generation)
      
      mock_generation.expects(:finish).with() do |params|
        params[:output] && params[:usage]
      end

      messages = [{ role: "user", content: "Hello" }]
      @client.chat(messages: messages, model: "claude-3", temperature: 0.7, system: "You are a helpful assistant")
    end

    should "finish generation with usage data" do
      mock_span = mock('span')
      mock_generation = mock('generation')
      @client.langfuse.stubs(:current_span).returns(mock_span)
      mock_span.stubs(:create_generation).returns(mock_generation)
      
      expected_usage = {
        prompt_tokens: 10,
        completion_tokens: 5,
        total_tokens: 15
      }
      
      mock_generation.expects(:finish).with() do |params|
        params[:usage] == expected_usage &&
        params[:output] == { "choices" => [{ "message" => { "content" => "answer" } }] }
      end

      messages = [{ role: "user", content: "Test input" }]
      @client.chat(messages: messages, model: "claude-3")
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
