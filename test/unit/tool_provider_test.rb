require File.expand_path("../../test_helper", __FILE__)
require "redmine_ai_helper/tool_provider"
require "redmine_ai_helper/agent_response"


# RedmineAiHelper::Agentクラスのテスト
# Mockやstubを使わずにテストを行う
# 本テスト実行時にはTestAgentクラスだけでなくProjectAgentなど他のAgentクラスも存在することを考慮してテストを行う
class RedmineAiHelper::ToolProviderTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :custom_values, :groups_users, :members, :member_roles, :roles, :user_preferences
  def setup
    @agent = RedmineAiHelper::ToolProvider.new(nil, nil)
    TestAgent.new
  end

  def test_list_tools
    result = RedmineAiHelper::ToolProvider.list_tools
    # resultの中に他のエージェントに混じってTestAgentのlist_toolsメソッドの結果が含まれていることを確認する
    # puts "result = #{result}"
    json = JSON.parse(result, symbolize_names: true)
    agents = json[:agents]
    # puts "agents = #{agents}"
    test_agent = agents.find { |agent| agent[:name] == "test_agent" }
    # puts "###### test_agent = #{test_agent}"
    test_agent_tools = test_agent[:tools]
    assert_equal 3, test_agent_tools.length
    assert_equal "tool1", test_agent_tools[0][:name]
    assert_equal "tool1 description", test_agent_tools[0][:description]
    assert_equal :arg1, test_agent_tools[0][:arguments].keys[0]
    assert_equal "string", test_agent_tools[0][:arguments][:arg1][:type]
    assert_equal "arg1 description", test_agent_tools[0][:arguments][:arg1][:description]
  end

  def test_call_tool
    result = @agent.call_tool(agent_name: "test_agent", name: "tool1", arguments: {})
    # puts "#### result = #{result}"
    assert_equal "success", result.status
    assert_equal "test_method called", result.value
  end

  def test_call_tool_with_invalid_agent
    result = @agent.call_tool(agent_name: "invalid_agent", name: "tool1", arguments: {})
    # puts "#### result = #{result}"
    assert_equal "error", result.status
    assert_equal "Agent not found.", result.error
  end

  def test_call_tool_with_invalid_tool
    result = @agent.call_tool(agent_name: "test_agent", name: "invalid_tool", arguments: {})
    # puts "#### result = #{result}"
    assert_equal "error", result.status
    assert result.is_error?
  end

  def test_call_tool_with_error
    result = @agent.call_tool(agent_name: "test_agent", name: "tool2", arguments: {})
    # puts "#### result = #{result}"
    assert_equal "error", result.status
    assert result.is_error?
  end

  def test_call_tool_with_exception
    result = @agent.call_tool(agent_name: "test_agent", name: "tool3", arguments: {})
    # puts "#### result = #{result}"
    assert_equal "error", result.status
    assert result.is_error?
  end
end

class TestAgent < RedmineAiHelper::BaseToolProvider
  def self.list_tools
    {
      tools: [
        {
          name: "tool1",
          description: "tool1 description",
          arguments: {
            arg1: {
              type: "string",
              description: "arg1 description",
            }
          },
        },
        {
          name: "tool2",
          description: "tool2 description",
          arguments: {
            arg2: {
              type: "string",
              description: "arg2 description",
            }
          },
        },
        {
          name: "tool3",
          description: "tool3 description",
          arguments: {
            arg3: {
              type: "string",
              description: "arg3 description",
            }
          },
        }
      ]
    }
  end

  def tool1(args)
    RedmineAiHelper::AgentResponse.create_success "test_method called"
  end

  def tool2(args)
    RedmineAiHelper::AgentResponse.create_error "error occurred"
  end

  def tool3(args)
    raise "exception occurred"
  end
end
