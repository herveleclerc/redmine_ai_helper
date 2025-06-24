require File.expand_path("../../test_helper", __FILE__)
require "redmine_ai_helper/base_agent"

class RedmineAiHelper::BaseAgentTest < ActiveSupport::TestCase
  def setup
    @openai_mock = BaseAgentTestModele::DummyOpenAIClient.new
    Langchain::LLM::OpenAI.stubs(:new).returns(@openai_mock)
    @project = Project.find(1)
    @params = {
      access_token: "test_access_token",
      uri_base: "http://example.com",
      organization_id: "test_org_id",
      model: "test_model",
      project: @project,
      langfuse: DummyLangfuse.new,
    }
    @agent = BaseAgentTestModele::TestAgent.new(@params)
    @agent2 = BaseAgentTestModele::TestAgent2.new(@params)
  end

  context "assistant" do
    should "return the instance of the agent" do
      assistant = @agent.assistant
      assert_instance_of RedmineAiHelper::Assistant, assistant
    end
  end

  context "available_tool_providers" do
    should "return an array of available tool providers with agent" do
      assert_equal [RedmineAiHelper::Tools::BoardTools], @agent.available_tool_providers
    end

    should "return an empty array with agent2" do
      assert_equal [], @agent2.available_tool_providers
    end
  end

  context "backstory" do
    should "return the backstory of the agent" do
      assert_equal "テストエージェントのバックストーリー", @agent.backstory
    end

    should "return the backstory of the agent2" do
      assert_equal "テストエージェント2のバックストーリー", @agent2.backstory
    end
  end

  context "available_tools" do
    should "return an array of available tools with agent" do
      tools = @agent.available_tools
      assert_equal 1, tools.size
    end

    should "return an empty array with agent2" do
      assert_equal [], @agent2.available_tools
    end
  end

  context "enabled?" do
    should "return true by default for agents" do
      assert_equal true, @agent.enabled?
    end

    should "return true for agent2" do
      assert_equal true, @agent2.enabled?
    end
  end

  context "perform_task" do
    should "perform the task and return a response" do
      messages = [{ role: "user", content: "テストメッセージ" }]
      response = @agent.perform_task(messages)
      assert response
    end
  end

  context "AgentList" do
    setup do
      @agent_list = RedmineAiHelper::AgentList.instance
      # Store original agents to restore later
      @original_agents = @agent_list.instance_variable_get(:@agents).dup
      # Clear existing agents and add test agents
      @agent_list.instance_variable_set(:@agents, [])
      @agent_list.add_agent("test_agent", "BaseAgentTestModele::TestAgent")
      @agent_list.add_agent("test_agent2", "BaseAgentTestModele::TestAgent2")
      @agent_list.add_agent("disabled_agent", "BaseAgentTestModele::DisabledAgent")
    end

    teardown do
      # Restore original agents to avoid interfering with other tests
      @agent_list.instance_variable_set(:@agents, @original_agents)
    end

    should "return only enabled agents in list_agents" do
      agents = @agent_list.list_agents
      agent_names = agents.map { |a| a[:agent_name] }
      
      assert_includes agent_names, "test_agent"
      assert_includes agent_names, "test_agent2"
      assert_not_includes agent_names, "disabled_agent"
    end
  end

  class DummyLangfuse
    def initialize(params = {})
      @params = params
    end

    def create_span(name:, input:)
      # Dummy implementation
    end

    def finish_current_span(output:)
      # Dummy implementation
    end

    def flush
      # Dummy implementation
    end
  end
end

module BaseAgentTestModele
  class TestAgent < RedmineAiHelper::BaseAgent
    def available_tool_providers
      [RedmineAiHelper::Tools::BoardTools]
    end

    def backstory
      "テストエージェントのバックストーリー"
    end

    def generate_response(prompt:, **options)
      # Generate dummy response for testing
      "テストエージェントの応答"
    end
  end

  class TestAgent2 < RedmineAiHelper::BaseAgent
    def backstory
      "テストエージェント2のバックストーリー"
    end

    def generate_response(prompt:, **options)
      # Generate dummy response for testing
      "テストエージェントの応答"
    end
  end

  class DisabledAgent < RedmineAiHelper::BaseAgent
    def backstory
      "無効化されたテストエージェント"
    end

    def enabled?
      false
    end

    def generate_response(prompt:, **options)
      # Generate dummy response for testing
      "無効化されたエージェントの応答"
    end
  end

  class DummyOpenAIClient < Langchain::LLM::OpenAI
    attr_accessor :langfuse

    def initialize(params = {})
      super(api_key: "aaaa")
    end

    def chat(params = {})
      answer = <<~EOS
        {
            "steps": [
              {
                    "name": "step1",
                    "step": "チケットを更新するために、必要な情報を整理する。"
              }
            ]
          }
      EOS

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
