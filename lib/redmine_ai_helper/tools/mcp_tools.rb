# frozen_string_literal: true
require "redmine_ai_helper/base_tools"
require "redmine_ai_helper/util/langchain_patch"

module RedmineAiHelper
  module Tools
    # McpTools is a specialized tool class for handling tasks using the Model Context Protocol (MCP).
    # It allows for the execution of commands and interaction with external tools or services.
    # This class is designed to be used in conjunction with the MCP server, which provides a JSON-RPC interface for tool execution.
    # The class dynamically generates tool classes based on the MCP server's JSON definition.
    # The generated tool classes can be used to define functions and execute commands with specific input schemas.
    class McpTools < RedmineAiHelper::BaseTools
      using RedmineAiHelper::Util::LangchainPatch

      class << self

        # Generate tool classes based on the definition JSON from the MCP server
        # The JSON format is as follows
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
        # @param name [String] The name of the tool class to be generated.
        # @param json [Hash] The JSON definition of the tool class.
        # @return [Class] The generated tool class.
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

        # Returns the number of times the MCP server has been executed.
        # Used to ensure the uniqueness of the message ID passed to the MCP server.
        def mcp_server_call_counter
          @mcp_server_call_counter ||= 0
        end

        # Increments the MCP server call counter and returns the previous value.
        def mcp_server_call_counter_up
          before = mcp_server_call_counter
          @mcp_server_call_counter = before + 1
          before
        end

        # Returns the command line for the MCP server.
        # Automatically overridden in the subclass to provide the command line.
        # @return [Array] An array representing the command line.
        def command_array
          []
        end

        # Returns the environment variables for the MCP server.
        # Automatically overridden in the subclass to provide the environment variables.
        # @return [Hash] A hash representing the environment variables.
        def env_hash
          {}
        end

        # Executes the MCP command with the provided input JSON.
        # @param input_json [String] The input JSON to be passed to the MCP server.
        # @return [String] The output from the MCP server.
        def execut_mcp_command(input_json:)
          env = env_hash
          cmd = command_array
          stdout, stderr, status = Open3.capture3(env, *cmd, { stdin_data: "#{input_json}\n" })

          unless status.success?
            raise "Error: #{stderr}"
          end
          stdout
        end

        # Loads the tools from the MCP server.
        # This method sends a request to the MCP server to retrieve the list of tools.
        # The response is then parsed and the tools are loaded into the class.
        # @return [Array] An array of loaded tools.
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

          # Parse the JSON to retrieve the list of tools
          tools = JSON.parse(stdout).dig("result", "tools") rescue nil

          load_json(json: tools)
        end

        # Loads the JSON definition of the tools and defines functions based on it.
        # This method iterates through the provided JSON and dynamically defines functions for each tool.
        #
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

      # Method executed when a tool from the MCP server is invoked
      # Requests the MCP server to execute the tool specified by name
      # @param name [String] The name of the tool to be executed.
      # @param args [Array] The arguments to be passed to the tool.
      # @return [String] The output from the MCP server.
      # @raise [ArgumentError] If the tool is not found.
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
