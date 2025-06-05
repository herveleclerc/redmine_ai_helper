require File.expand_path("../../../test_helper", __FILE__)
require "mocha/minitest"

class RedmineAiHelper::LangfuseUtil::LangfuseWrapperTest < ActiveSupport::TestCase
  setup do
    RedmineAiHelper::Util::ConfigFile.stubs(:load_config).returns({
      langfuse: {
        public_key: "test_public_key",
        endpoint: nil,
      },
    })
    Langfuse::Client.stubs(:instance).returns(DummyClient.new)

    @langfuse = RedmineAiHelper::LangfuseUtil::LangfuseWrapper.new(input: "test input")
    @langfuse.stubs(:enabled?).returns(true)
  end

  teardown do
    Langfuse.shutdown()
  end

  should "create a span with correct parameters" do
    @langfuse.create_span(name: "test_span", input: "test_input")
    assert @langfuse.current_span
  end

  should "find the current span" do
    span = @langfuse.create_span(name: "test_span", input: "test_input")
    assert_equal span, @langfuse.current_span
    assert @langfuse.finish_current_span(output: "test output")
  end

  context "SpanWrapper" do
    should "finish the span and return the span object" do
      span = @langfuse.create_span(name: "test_span", input: "test_input")
      assert span.finish(output: "end output")
    end

    should "create generation" do
      span = @langfuse.create_span(name: "test_span", input: "test_input")
      generation = span.create_generation(name: "aaa", messages: ["messages"], model: "test_model")
      assert generation
      assert generation
    end
  end

  context "GenerationWrapper" do
    should "finish the generation and return the generation object" do
      span = @langfuse.create_span(name: "test_span", input: "test_input")
      generation = span.create_generation(name: "test_gen", messages: ["message1", "message2"], model: "test_model")
      assert generation.finish(output: "test output", usage: { prompt_tokens: 10, completion_tokens: 5 })
    end
  end

  class DummyClient
    def trace(attr = {})
      Langfuse::Models::Trace.new(
        id: "test_trace_id",
        name: attr[:name],
        user_id: attr[:user_id],
        input: attr[:input],
        metadata: attr[:metadata],
      )
    end

    def shutdown(**args)
      true
    end

    def span(attr = {})
      Langfuse::Models::Span.new(
        id: "test_span_id",
        name: attr[:name],
        trace_id: 1,
        input: attr[:input],
        parent_span_id: attr[:parent_span_id],
      )
    end

    def generation(attr = {})
      Langfuse::Models::Generation.new(
        id: "test_generation_id",
        name: attr[:name],
        messages: attr[:messages],
        model: attr[:model],
        output: "test output",
        span_id: "test_span_id",
      )
    end

    def update_span(span)
      span
    end

    def update_generation(generation)
      generation
    end
  end
end
