require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/util/mcp_tools_loader"

class RedmineAiHelper::Util::McpToolsLoaderTest < ActiveSupport::TestCase
  teardown do
  end
  context "McpToolsLoader" do
    teardown do
      # Clean up stubs
      RedmineAiHelper::Util::McpToolsLoader.instance_variable_set(:@list, nil)
      RedmineAiHelper::Util::McpToolsLoader.instance_variable_set(:@config_file, nil)
    end
    should "return config file path" do
      tools_loader = RedmineAiHelper::Util::McpToolsLoader.instance
      config_file = tools_loader.config_file
      assert_equal File.join(Rails.root, "config", "ai_helper", "config.json"), config_file
    end
  end

  context "McpToolsLoader with nonexists file" do
    should "return empty list" do
      test_config_file = File.expand_path("non_existent_file.json", __FILE__)
      Rails.root.stubs(:join).returns(test_config_file) do
        tools = RedmineAiHelper::Util::McpToolsLoader.load
        assert_equal 0, tools.length
      end
    end
  end
  context "McpToolsLoader with test_config" do
    should "load tools from config file" do
      test_config_file = File.expand_path("../../../test_config.json", __FILE__)
      Rails.root.stubs(:join).returns(test_config_file) do
        tools = RedmineAiHelper::Util::McpToolsLoader.load
        assert_equal 2, tools.length
        assert_equal "McpSlack", tools[0].name
        assert_equal "McpFilesystem", tools[1].name
      end
    end
  end
end
