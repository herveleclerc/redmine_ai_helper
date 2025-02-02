require File.expand_path("../../test_helper", __FILE__)
require "redmine_ai_helper/agent"

class RedmineAiHelper::AgentTest < ActiveSupport::TestCase
  def setup
    @client = mock("client")
    @model = mock("model")
    @agent = RedmineAiHelper::Agent.new(@client, @model)
  end

  def test_initialize
    assert_not_nil @agent
    assert_equal @client, @agent.instance_variable_get(:@client)
    assert_equal @model, @agent.instance_variable_get(:@model)
  end

  def test_list_tools
    RedmineAiHelper::BaseAgent.stubs(:agent_list).returns([
      { name: "TestAgent", class: TestAgent },
    ])
    TestAgent.stubs(:list_tools).returns(["tool1", "tool2"])

    expected_output = JSON.pretty_generate({
      agents: [
        {
          name: "TestAgent",
          tools: ["tool1", "tool2"],
        },
      ],
    })

    assert_equal expected_output, RedmineAiHelper::Agent.list_tools
  end

  def test_call_tool_success
    params = {
      agent_name: "TestAgent",
      name: "test_method",
      arguments: { key: "value" },
    }

    agent_instance = mock("agent_instance")
    agent_instance.expects(:respond_to?).with("test_method").returns(true)
    agent_instance.expects(:send).with("test_method", { key: "value" }).returns("success")

    RedmineAiHelper::BaseAgent.stubs(:agent_class).with("TestAgent").returns(TestAgent)
    TestAgent.stubs(:new).returns(agent_instance)

    response = @agent.call_tool(params)
    assert_equal "success", response
  end

  def test_call_tool_method_not_found
    params = {
      agent_name: "TestAgent",
      name: "non_existent_method",
      arguments: { key: "value" },
    }

    agent_instance = mock("agent_instance")
    agent_instance.expects(:respond_to?).with("non_existent_method").returns(false)

    RedmineAiHelper::BaseAgent.stubs(:agent_class).with("TestAgent").returns(TestAgent)
    TestAgent.stubs(:new).returns(agent_instance)

    response = @agent.call_tool(params)
    assert response.is_a?(RedmineAiHelper::AgentResponse)
    assert_equal "Method non_existent_method not found", response.error
  end

  def test_call_tool_exception
    params = {
      agent_name: "TestAgent",
      name: "test_method",
      arguments: { key: "value" },
    }

    agent_instance = mock("agent_instance")
    agent_instance.expects(:respond_to?).with("test_method").returns(true)
    agent_instance.expects(:send).with("test_method", { key: "value" }).raises(StandardError.new("test error"))

    RedmineAiHelper::BaseAgent.stubs(:agent_class).with("TestAgent").returns(TestAgent)
    TestAgent.stubs(:new).returns(agent_instance)

    response = @agent.call_tool(params)
    assert response.is_a?(RedmineAiHelper::AgentResponse)
    assert_equal "test error", response.error
  end
end

class TestAgent
  def self.list_tools
    ["tool1", "tool2"]
  end

  def test_method(args)
    "success"
  end
end
