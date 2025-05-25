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

  context "McpToolsLoader with test_config" do
    setup do
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      loader.instance_variable_set(:@config_file, nil)
      loader.instance_variable_set(:@list, nil)
    end

    teardown do
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      loader.instance_variable_set(:@config_file, nil)
      loader.instance_variable_set(:@list, nil)
    end

    should "load tools from config file" do
      test_config_file = File.expand_path("../../../test_config.json", __FILE__)

      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      loader.instance_variable_set(:@config_file, test_config_file)
      tools = RedmineAiHelper::Util::McpToolsLoader.load

      assert_not_nil tools, "tools should not be nil"
      assert tools.is_a?(Array), "tools should be an Array"
      assert_equal 2, tools.length, "tools count should be 1"
      assert_equal "McpSlack", tools[0].name, "First tool should be McpSlack"
    end

    should "return empty array if config file does not exist" do
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      loader.instance_variable_set(:@config_file, "non_existent_config.json")

      tools = RedmineAiHelper::Util::McpToolsLoader.load

      assert_equal [], tools, "tools should be an empty array when config file does not exist"
    end
  end
end
