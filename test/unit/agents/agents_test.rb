require File.expand_path("../../../test_helper", __FILE__)

class AgentsTest < ActiveSupport::TestCase
  setup do
  end
  context "BoardAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::BoardAgent.new
      RedmineAiHelper::LlmProvider.stubs(:get_llm).returns({})
    end

    should "return correct tool providers" do
      assert_equal [RedmineAiHelper::Tools::BoardTools], @agent.available_tool_providers
    end
  end

  context "IssueAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::IssueAgent.new({ project: Project.find(1) })
    end

    should "return correct tool providers" do
      assert_equal [
                     RedmineAiHelper::Tools::IssueTools,
                     RedmineAiHelper::Tools::ProjectTools,
                     RedmineAiHelper::Tools::UserTools,
                     RedmineAiHelper::Tools::IssueSearchTools,
                   ], @agent.available_tool_providers
    end

    should "return correct backstory" do
      assert @agent.backstory.include?("You are a issue agent for the RedmineAIHelper plugin")
    end
  end

  context "IssueUpdateAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::IssueUpdateAgent.new({ project: Project.find(1) })
    end

    should "return correct tool providers" do
      assert_equal [
                     RedmineAiHelper::Tools::IssueTools,
                     RedmineAiHelper::Tools::IssueUpdateTools,
                     RedmineAiHelper::Tools::ProjectTools,
                     RedmineAiHelper::Tools::UserTools,
                   ], @agent.available_tool_providers
    end

    should "return correct backstory" do
      assert @agent.backstory.include?("You are the issue update agent of the RedmineAIHelper plugin")
    end
  end

  context "RepositoryAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::RepositoryAgent.new
    end

    should "return correct tool providers" do
      assert_equal [RedmineAiHelper::Tools::RepositoryTools], @agent.available_tool_providers
    end
  end

  context "SystemAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::SystemAgent.new
    end

    should "return correct tool providers" do
      assert_equal [RedmineAiHelper::Tools::SystemTools], @agent.available_tool_providers
    end
  end

  context "UserAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::UserAgent.new
    end

    should "return correct tool providers" do
      assert_equal [RedmineAiHelper::Tools::UserTools], @agent.available_tool_providers
    end
  end

  context "ProjectAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::ProjectAgent.new
    end

    should "return correct tool providers" do
      assert_equal [RedmineAiHelper::Tools::ProjectTools], @agent.available_tool_providers
    end
  end

  context "WikiAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::WikiAgent.new
    end

    should "return correct tool providers" do
      assert_equal [RedmineAiHelper::Tools::WikiTools], @agent.available_tool_providers
    end
  end

  context "VersionAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::VersionAgent.new
    end

    should "return correct tool providers" do
      assert_equal [RedmineAiHelper::Tools::VersionTools], @agent.available_tool_providers
    end
  end

  context "McpAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::McpAgent.new
    end

    should "return correct role" do
      assert_equal "mcp_agent", @agent.role
    end

    should "return correct backstory" do
      assert @agent.backstory.include?("You are the MCP agent of the RedmineAIHelper plugin")
    end

    context "mcp_agent" do
      should "return correct tool providers" do
        assert_equal RedmineAiHelper::Util::McpToolsLoader.load, @agent.available_tool_providers
      end
    end

    context "enabled?" do
      should "return false when no available tools" do
        @agent.stubs(:available_tools).returns([])
        assert_equal false, @agent.enabled?
      end

      should "return true when available tools exist" do
        @agent.stubs(:available_tools).returns([{ "type" => "function", "function" => { "name" => "test_tool" } }])
        assert_equal true, @agent.enabled?
      end
    end
  end
end
