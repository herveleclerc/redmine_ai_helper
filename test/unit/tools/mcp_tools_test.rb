require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/tools/mcp_tools"

class RedmineAiHelper::Tools::McpToolsTest < ActiveSupport::TestCase
  context "McpTools" do
    setup do
      @tools = RedmineAiHelper::Tools::McpTools.new
    end

    should "return empty command array" do
      assert_equal [], RedmineAiHelper::Tools::McpTools.command_array
    end

    should "return empty env hash" do
      assert_equal({}, RedmineAiHelper::Tools::McpTools.env_hash)
    end

    context "method_missing" do
      setup do
        @command_json = {
          "command" => "npx",
          "args" => [
            "-y",
            "@modelcontextprotocol/server-filesystem",
            "/tmp",
          ],
        }
        tool_class = RedmineAiHelper::Tools::McpTools.generate_tool_class(
          name: "filesystem2",
          json: @command_json,
        )
        @filesystem_tool = tool_class.new
      end

      should "raise ArgumentError if function not exist" do
        assert_raises ArgumentError do
          @filesystem_tool.non_existent_function
        end
      end
    end
  end
end
