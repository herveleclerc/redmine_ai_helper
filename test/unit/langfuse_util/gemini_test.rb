require File.expand_path("../../../test_helper", __FILE__)

class RedmineAiHelper::LangfuseUtil::GeminiTest < ActiveSupport::TestCase
  context "Gemini" do
    setup do
      Langchain::LLM::GoogleGeminiResponse.stubs(:new).returns(DummyGeminiResponse.new)
      Net::HTTP.stubs(:new).returns(DummyHttp.new)
      Net::HTTP::Post.stubs(:new).returns(DummyHttpPost.new)
      @gemini = RedmineAiHelper::LangfuseUtil::Gemini.new(api_key: "test")
      RedmineAiHelper::LangfuseUtil::LangfuseWrapper.stubs(:new).returns(DummyLangfuse.new)
      langfuse = RedmineAiHelper::LangfuseUtil::LangfuseWrapper.new(input: "Test input for Langfuse")
      langfuse.stubs(:enabled?).returns(true)
      @gemini.langfuse = langfuse
      @gemini.langfuse.create_span(name: "test_span", input: "test_input")
    end

    context "chat" do
      should "create an observation with correct parameters" do
        messages = [{ role: "user", content: "Test input" }]

        answer = @gemini.chat(messages: messages, model: "gemini-1.0", temperature: 0.5)
        assert answer
      end
    end
  end

  class DummyGeminiResponse
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
      endprompt_tokens + completion_tokens
    end

    def endprompt_tokens
      10
    end
  end

  class DummyHttp
    attr_accessor :use_ssl, :read_timeout, :open_timeout

    def request(*args)
      return Response.new
    end

    # Dummy HTTP response class for testing
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

  class DummyHttpPost
    attr_accessor :content_type, :body
  end

  class DummyLangfuse
    def observation(name:, input:, output:, model: nil, metadata: {})
      DummyObservation.new
    end

    def span(name:, input:)
      @current_span = DummySpan.new
    end

    def flush
      # No-op for testing
    end

    def create_span(name:, input:)
      @current_span = DummySpan.new
      @current_span
    end

    def current_span
      @current_span
    end
  end

  class DummySpan
    def create_generation(name:, messages:, model:, temperature:, max_tokens:)
      DummyGeneration.new
    end
  end

  class DummyGeneration
    def finish(output:, usage: {})
      # No-op for testing
    end
  end

  class DummyObservation
    def finish(output:)
      # No-op for testing
    end
  end
end
