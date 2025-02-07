require File.expand_path("../../test_helper", __FILE__)
require "redmine_ai_helper/tool_provider"


# RedmineAiHelper::Providerクラスのテスト
# Mockやstubを使わずにテストを行う
# 本テスト実行時にはTestProviderクラスだけでなくProjectProviderなど他のProviderクラスも存在することを考慮してテストを行う
class RedmineAiHelper::ToolProviderTest < ActiveSupport::TestCase
  fixtures :projects, :issues, :issue_statuses, :trackers, :enumerations, :users, :issue_categories, :versions, :custom_fields, :custom_values, :groups_users, :members, :member_roles, :roles, :user_preferences
  def setup
    @provider = RedmineAiHelper::ToolProvider.new(nil, nil)
    TestProvider.new
  end

  def test_list_tools
    result = RedmineAiHelper::ToolProvider.list_tools
    # resultの中に他のエージェントに混じってTestProviderのlist_toolsメソッドの結果が含まれていることを確認する
    # puts "#### result = #{result}"
    json = JSON.parse(result, symbolize_names: true)
    providers = json[:providers]
    # puts "providers = #{providers}"
    test_provider = providers.find { |provider| provider[:name] == "test_provider" }
    # puts "###### test_provider = #{test_provider}"
    test_provider_tools = test_provider[:tools]
    assert_equal 3, test_provider_tools.length
    assert_equal "tool1", test_provider_tools[0][:name]
    assert_equal "tool1 description", test_provider_tools[0][:description]
    assert_equal :arg1, test_provider_tools[0][:arguments].keys[0]
    assert_equal "string", test_provider_tools[0][:arguments][:arg1][:type]
    assert_equal "arg1 description", test_provider_tools[0][:arguments][:arg1][:description]
  end

  def test_call_tool
    result = @provider.call_tool(provider: "test_provider", name: "tool1", arguments: {})
    # puts "#### result = #{result}"
    assert_equal "success", result.status
    assert_equal "test_method called", result.value
  end

  def test_call_tool_with_invalid_provider
    result = @provider.call_tool(provider: "invalid_provider", name: "tool1", arguments: {})
    # puts "#### result = #{result}"
    assert_equal "error", result.status
    assert_equal "Provider not found.: invalid_provider", result.error
  end

  def test_call_tool_with_invalid_tool
    result = @provider.call_tool(provider: "test_provider", name: "invalid_tool", arguments: {})
    # puts "#### result = #{result}"
    assert_equal "error", result.status
    assert result.is_error?
  end

  def test_call_tool_with_error
    result = @provider.call_tool(provider: "test_provider", name: "tool2", arguments: {})
    # puts "#### result = #{result}"
    assert_equal "error", result.status
    assert result.is_error?
  end

  def test_call_tool_with_exception
    result = @provider.call_tool(provider: "test_provider", name: "tool3", arguments: {})
    # puts "#### result = #{result}"
    assert_equal "error", result.status
    assert result.is_error?
  end
end

class TestProvider < RedmineAiHelper::BaseToolProvider
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
    RedmineAiHelper::ToolResponse.create_success "test_method called"
  end

  def tool2(args)
    RedmineAiHelper::ToolResponse.create_error "error occurred"
  end

  def tool3(args)
    raise "exception occurred"
  end
end
