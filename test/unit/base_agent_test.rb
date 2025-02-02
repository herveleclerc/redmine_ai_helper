require File.expand_path("../../test_helper", __FILE__)

class BaseAgentTest < ActiveSupport::TestCase
  def setup
    @agent_name = "TestAgent"
    @agent_class = Class.new
    RedmineAiHelper::BaseAgent::AGENT_LIST.clear
  end

  def test_add_agent
    RedmineAiHelper::BaseAgent.add_agent(name: @agent_name, class: @agent_class)
    assert_equal 1, RedmineAiHelper::BaseAgent::AGENT_LIST.size
    assert_equal @agent_name, RedmineAiHelper::BaseAgent::AGENT_LIST.first[:name]
    assert_equal @agent_class, RedmineAiHelper::BaseAgent::AGENT_LIST.first[:class]
  end

  def test_agent_list
    RedmineAiHelper::BaseAgent.add_agent(name: @agent_name, class: @agent_class)
    agent_list = RedmineAiHelper::BaseAgent.agent_list
    assert_equal 1, agent_list.size
    assert_equal @agent_name, agent_list.first[:name]
    assert_equal @agent_class, agent_list.first[:class]
  end

  def test_agent_class
    RedmineAiHelper::BaseAgent.add_agent(name: @agent_name, class: @agent_class)
    agent_class = RedmineAiHelper::BaseAgent.agent_class(@agent_name)
    assert_equal @agent_class, agent_class
  end

  def test_list_tools
    assert_raises(NotImplementedError) do
      RedmineAiHelper::BaseAgent.list_tools
    end
  end
end
