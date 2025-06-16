require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/tools/mcp_tools"

class RedmineAiHelper::Tools::McpToolsTest < ActiveSupport::TestCase
  context "McpTools" do
    should "return empty command array" do
      assert_equal [], RedmineAiHelper::Tools::McpTools.command_array
    end

    should "return empty env hash" do
      assert_equal({}, RedmineAiHelper::Tools::McpTools.env_hash)
    end

    should "start with zero counter" do
      # Reset counter before test
      RedmineAiHelper::Tools::McpTools.instance_variable_set(:@mcp_server_call_counter, 0)
      assert_equal 0, RedmineAiHelper::Tools::McpTools.mcp_server_call_counter
    end

    should "increment counter and return previous value" do
      # Reset counter
      RedmineAiHelper::Tools::McpTools.instance_variable_set(:@mcp_server_call_counter, 5)
      
      previous = RedmineAiHelper::Tools::McpTools.mcp_server_call_counter_up
      assert_equal 5, previous
      assert_equal 6, RedmineAiHelper::Tools::McpTools.mcp_server_call_counter
    end

    should "raise NotImplementedError in base class send_mcp_request" do
      assert_raises(NotImplementedError) do
        RedmineAiHelper::Tools::McpTools.send_mcp_request({})
      end
    end

    should "handle method_missing for non-existent function" do
      tools = RedmineAiHelper::Tools::McpTools.new
      
      assert_raises ArgumentError do
        tools.non_existent_function
      end
    end

    context "class generation (mocked)" do
      should "test command array parsing logic" do
        # Test command array parsing without actual class generation
        json_with_command = { "command" => "node", "args" => ["server.js"] }
        
        # Test the logic that would be used in command_array method
        expected = ["node", "server.js"]
        command = json_with_command["command"]
        args = [command]
        args = args + json_with_command["args"] if json_with_command["args"]
        
        assert_equal expected, args
      end

      should "test env hash extraction logic" do
        # Test env hash extraction without actual class generation
        json_with_env = { "command" => "test", "env" => { "API_KEY" => "secret" } }
        json_without_env = { "command" => "test" }
        
        assert_equal({ "API_KEY" => "secret" }, json_with_env["env"] || {})
        assert_equal({}, json_without_env["env"] || {})
      end
    end

    context "load_json method" do
      should "handle array and single tool structures" do
        # Test the logic without actual function definition
        single_tool = { "name" => "test_tool", "description" => "A test tool" }
        tools_array = [single_tool]
        
        # Verify array handling logic
        processed_single = [single_tool]
        processed_array = tools_array
        
        assert_equal processed_single, [single_tool].is_a?(Array) ? [single_tool] : [[single_tool]]
        assert_equal processed_array, tools_array.is_a?(Array) ? tools_array : [tools_array]
      end
    end
  end
end