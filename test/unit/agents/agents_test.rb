require File.expand_path("../../../test_helper", __FILE__)

class AgentsTest < ActiveSupport::TestCase
  context "BoardAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::BoardAgent.new
    end

    should "return correct tool providers" do
      assert_equal ["board_tool_provider"], @agent.available_tool_providers
    end
  end

  context "IssueAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::IssueAgent.new
    end

    should "return correct tool providers" do
      assert_equal  ["issue_tool_provider", "project_tool_provider", "user_tool_provider"], @agent.available_tool_providers
    end
  end

  context "RepositoryAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::RepositoryAgent.new
    end

    should "return correct tool providers" do
      assert_equal ["repository_tool_provider"], @agent.available_tool_providers
    end
  end

  context "SystemAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::SystemAgent.new
    end

    should "return correct tool providers" do
      assert_equal ["system_tool_provider"], @agent.available_tool_providers
    end
  end

  context "UserAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::UserAgent.new
    end

    should "return correct tool providers" do
      assert_equal ["user_tool_provider"], @agent.available_tool_providers
    end
  end

  context "ProjectAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::ProjectAgent.new
    end

    should "return correct tool providers" do
      assert_equal ["project_tool_provider"], @agent.available_tool_providers
    end
  end

  context "WikiAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::WikiAgent.new
    end

    should "return correct tool providers" do
      assert_equal ["wiki_tool_provider"], @agent.available_tool_providers
    end
  end

  context "VersionAgent" do
    setup do
      @agent = RedmineAiHelper::Agents::VersionAgent.new
    end

    should "return correct tool providers" do
      assert_equal ["version_tool_provider"], @agent.available_tool_providers
    end
  end
end
