require "redmine_ai_helper/base_tools"
require "redmine_ai_helper/util/langchain_patch"

module RedmineAiHelper
  module Tools
    class McpTools < RedmineAiHelper::BaseTools
      using RedmineAiHelper::Util::LangchainPatch

      class << self

        # MCP serverの定義JSONを元にツールクラスを生成する
        # JSONの形式は以下の通り
        # {
        #     "command": "npx",
        #     "args": [
        #       "-y",
        #       "@modelcontextprotocol/server-slack"
        #     ],
        #     "env": {
        #       "SLACK_BOT_TOKEN": "xoxb-your-bot-token",
        #       "SLACK_TEAM_ID": "T01234567"
        #     }
        # }
        def generate_tool_class(name:, json:)
          class_name = "Mcp#{name.capitalize}"
          Object.const_set(class_name,
                           Class.new(RedmineAiHelper::Tools::McpTools) do
            @mcp_server_json = json
            @mcp_server_json.freeze
            @mcp_server_commandline = nil
            @mcp_server_call_counter = 0
            def self.command_array
              return @mcp_server_commandline if @mcp_server_commandline
              command = @mcp_server_json["command"]
              args = [command]
              args = args + @mcp_server_json["args"] if @mcp_server_json["args"]
              @mcp_server_commandline = args
            end

            def self.env_hash
              @mcp_server_json["env"] || {}
            end
          end)
          klass = Object.const_get(class_name)
          klass.load_from_mcp_server
          klass
        end

        def mcp_server_call_counter
          @mcp_server_call_counter ||= 0
        end

        def mcp_server_call_counter_up
          before = mcp_server_call_counter
          @mcp_server_call_counter = before + 1
          before
        end

        def command_array
          []
        end

        def env_hash
          {}
        end

        def execut_mcp_command(input_json:)
          env = env_hash
          cmd = command_array
          stdout, stderr, status = Open3.capture3(env, *cmd, { stdin_data: "#{input_json}\n" })

          unless status.success?
            raise "Error: #{stderr}"
          end
          stdout
        end

        def load_from_mcp_server
          # input_data = '{"method": "tools/list", "params": {}, "jsonrpc": "2.0", "id": 0}'
          input_data = {
            "method" => "tools/list",
            "params" => {},
            "jsonrpc" => "2.0",
            "id" => mcp_server_call_counter_up,
          }.to_json
          @mcp_server_call_counter += 1
          stdout = execut_mcp_command(input_json: input_data)

          # JSONをパースして、toolsのリストを取得
          tools = JSON.parse(stdout).dig("result", "tools") rescue nil

          load_json(json: tools)
        end

        #
        # define functions from mcp server json
        def load_json(json:)
          tools = [json]
          tools = json if json.is_a?(Array)
          tools.each do |tool|
            define_function tool["name"], description: tool["description"] do
              input_schema = tool["inputSchema"]
              if input_schema["properties"].empty?
                input_schema["properties"] = { "dummy_property" => { "type" => "string", "description" => "dummy property" } }
              end
              build_properties_from_json(input_schema)
            end
          end
        end
      end

      def method_missing(name, *args)
        schema = self.class.function_schemas.to_openai_format
        function = schema.find { |f| f.dig(:function, :name).end_with?("__#{name}") }

        raise ArgumentError, "Function not found: #{name}" unless function

        input_json = {
          "method" => "tools/call",
          "params" => {
            "name" => name.to_s,
            "arguments" => args[0],
          },
          "jsonrpc" => "2.0",
          "id" => self.class.mcp_server_call_counter_up,
        }.to_json

        stdout = self.class.execut_mcp_command(input_json: input_json)

        stdout
      end
    end
  end
end
