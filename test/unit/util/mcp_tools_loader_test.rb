require File.expand_path("../../../test_helper", __FILE__)
require "redmine_ai_helper/util/mcp_tools_loader"

class RedmineAiHelper::Util::McpToolsLoaderTest < ActiveSupport::TestCase
  teardown do
    # Clean up any test files
    RedmineAiHelper::Util::McpToolsLoader.instance.instance_variable_set(:@list, nil)
  end
  
  context "McpToolsLoader" do
    should "be a singleton" do
      instance1 = RedmineAiHelper::Util::McpToolsLoader.instance
      instance2 = RedmineAiHelper::Util::McpToolsLoader.instance
      assert_same instance1, instance2
    end

    should "generate empty tools list when no config file exists" do
      File.stubs(:exist?).returns(false)
      
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      loader.instance_variable_set(:@list, nil)
      
      tools = loader.generate_tools_instances
      assert_equal [], tools
    end

    should "handle JSON parsing errors gracefully" do
      File.stubs(:exist?).returns(true)
      File.stubs(:read).returns("invalid json {")
      
      # Mock logger to avoid config file dependency
      mock_logger = mock('logger')
      mock_logger.stubs(:error)
      
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      loader.stubs(:ai_helper_logger).returns(mock_logger)
      loader.instance_variable_set(:@list, nil)
      
      tools = loader.generate_tools_instances
      assert_equal [], tools
    end

    should "handle file read errors gracefully" do
      File.stubs(:exist?).returns(true)
      File.stubs(:read).raises(Errno::ENOENT.new("File not found"))
      
      # Mock logger to avoid config file dependency
      mock_logger = mock('logger')
      mock_logger.stubs(:error)
      
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      loader.stubs(:ai_helper_logger).returns(mock_logger)
      loader.instance_variable_set(:@list, nil)
      
      tools = loader.generate_tools_instances
      assert_equal [], tools
    end

    should "validate URL formats correctly" do
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      
      # Valid URLs
      assert loader.send(:valid_url?, 'http://example.com')
      assert loader.send(:valid_url?, 'https://example.com')
      
      # Invalid URLs
      assert_equal false, loader.send(:valid_url?, 'ftp://example.com')
      assert_equal false, loader.send(:valid_url?, 'invalid-url')
      assert_equal false, loader.send(:valid_url?, '')
      assert_equal false, loader.send(:valid_url?, nil)
    end

    should "determine legacy transport types correctly" do
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      
      # Should detect stdio from command
      config_with_command = { 'command' => 'node' }
      assert_equal 'stdio', loader.send(:determine_legacy_transport, config_with_command)
      
      # Should detect stdio from args
      config_with_args = { 'args' => ['server.js'] }
      assert_equal 'stdio', loader.send(:determine_legacy_transport, config_with_args)
      
      # Should detect http from url
      config_with_url = { 'url' => 'http://localhost:3000' }
      assert_equal 'http', loader.send(:determine_legacy_transport, config_with_url)
      
      # Should default to stdio
      empty_config = {}
      assert_equal 'stdio', loader.send(:determine_legacy_transport, empty_config)
    end

    should "validate server configurations" do
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      
      # Valid configurations
      valid_stdio_config = { 'command' => 'node', 'args' => ['server.js'] }
      assert loader.send(:valid_server_config?, valid_stdio_config)
      
      valid_http_config = { 'url' => 'http://localhost:3000' }
      assert loader.send(:valid_server_config?, valid_http_config)
      
      # Invalid configurations
      assert_equal false, loader.send(:valid_server_config?, nil)
      assert_equal false, loader.send(:valid_server_config?, "not a hash")
      assert_equal false, loader.send(:valid_server_config?, {})
      assert_equal false, loader.send(:valid_server_config?, { 'command' => '' })
      assert_equal false, loader.send(:valid_server_config?, { 'url' => '' })
    end

    should "cache results on subsequent calls" do
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      loader.instance_variable_set(:@list, nil)
      
      # Mock File operations to avoid actual file I/O
      File.stubs(:exist?).returns(true)
      File.stubs(:read).returns('{"mcpServers": {}}')
      RedmineAiHelper::Util::ConfigurationMigrator.stubs(:migrate_config).returns({"mcpServers" => {}})
      
      # Use expects to ensure load_and_migrate_config is called only once
      loader.expects(:load_and_migrate_config).once.returns({"mcpServers" => {}})
      
      # First call - should load from file and cache the result
      tools1 = loader.generate_tools_instances
      
      # Verify the result was cached
      cached_list = loader.instance_variable_get(:@list)
      assert_not_nil cached_list, "Result should be cached after first call"
      
      # Second call - should use cache (no additional load_and_migrate_config call)
      tools2 = loader.generate_tools_instances
      
      # Both should return empty arrays (since no valid servers)
      assert_equal [], tools1, "First call should return empty array"
      assert_equal [], tools2, "Second call should return same empty array"
      
      # Verify both calls returned the same cached object
      assert_same cached_list, tools2, "Second call should return cached result"
      
      # The expectation ensures that load_and_migrate_config was called exactly once
    end

    should "have class method load that delegates to instance" do
      # Mock instance method
      mock_tools = [{ name: 'test', json: { command: 'test' } }]
      RedmineAiHelper::Util::McpToolsLoader.any_instance.stubs(:generate_tools_instances).returns(mock_tools)
      
      # Test class method exists and works
      result = RedmineAiHelper::Util::McpToolsLoader.load
      assert_equal mock_tools, result
    end

    should "have class method loader that returns singleton instance" do
      # Test loader method returns the singleton instance
      loader1 = RedmineAiHelper::Util::McpToolsLoader.loader
      loader2 = RedmineAiHelper::Util::McpToolsLoader.loader
      
      assert_same loader1, loader2
      assert_same RedmineAiHelper::Util::McpToolsLoader.instance, loader1
    end

    should "return correct config file path" do
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      expected_path = Rails.root.join("config", "ai_helper", "config.json").to_s
      
      assert_equal expected_path, loader.config_file
      
      # Test memoization
      assert_same loader.config_file, loader.config_file
    end

    should "return config_data when file exists" do
      valid_config = {
        "mcpServers" => {
          "test_server" => {
            "command" => "node",
            "args" => ["server.js"]
          }
        }
      }
      
      File.stubs(:exist?).returns(true)
      File.stubs(:read).returns(valid_config.to_json)
      RedmineAiHelper::Util::ConfigurationMigrator.stubs(:migrate_config).returns(valid_config)
      
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      config_data = loader.config_data
      
      assert_equal valid_config, config_data
    end

    should "return empty hash for config_data when file does not exist" do
      File.stubs(:exist?).returns(false)
      
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      config_data = loader.config_data
      
      assert_equal({}, config_data)
    end

    should "successfully generate tool instances with valid configuration" do
      valid_config = {
        "mcpServers" => {
          "test_server" => {
            "command" => "node",
            "args" => ["server.js"]
          }
        }
      }
      
      # Mock file operations
      File.stubs(:exist?).returns(true)
      File.stubs(:read).returns(valid_config.to_json)
      RedmineAiHelper::Util::ConfigurationMigrator.stubs(:migrate_config).returns(valid_config)
      
      # Mock tool class generation
      mock_tool_class = Class.new
      RedmineAiHelper::Tools::McpTools.stubs(:generate_tool_class).returns(mock_tool_class)
      
      # Mock logger
      mock_logger = mock('logger')
      mock_logger.stubs(:info)
      mock_logger.stubs(:warn)
      mock_logger.stubs(:error)
      
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      loader.stubs(:ai_helper_logger).returns(mock_logger)
      loader.instance_variable_set(:@list, nil)
      
      tools = loader.generate_tools_instances
      
      assert_equal [mock_tool_class], tools
    end

    should "handle tool class generation errors gracefully" do
      valid_config = {
        "mcpServers" => {
          "test_server" => {
            "command" => "node",
            "args" => ["server.js"]
          }
        }
      }
      
      # Mock file operations
      File.stubs(:exist?).returns(true)
      File.stubs(:read).returns(valid_config.to_json)
      RedmineAiHelper::Util::ConfigurationMigrator.stubs(:migrate_config).returns(valid_config)
      
      # Mock tool class generation to raise an error
      RedmineAiHelper::Tools::McpTools.stubs(:generate_tool_class).raises(StandardError, "Tool generation failed")
      
      # Mock logger
      mock_logger = mock('logger')
      mock_logger.expects(:info).never
      mock_logger.expects(:error).with("Error generating tool class for test_server: Tool generation failed")
      mock_logger.stubs(:debug?).returns(false)
      mock_logger.stubs(:warn)
      
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      loader.stubs(:ai_helper_logger).returns(mock_logger)
      loader.instance_variable_set(:@list, nil)
      
      # Should not raise error, should return empty array
      tools = loader.generate_tools_instances
      assert_equal [], tools
    end

    should "log debug backtrace when debug logging is enabled" do
      valid_config = {
        "mcpServers" => {
          "test_server" => {
            "command" => "node",
            "args" => ["server.js"]
          }
        }
      }
      
      # Mock file operations
      File.stubs(:exist?).returns(true)
      File.stubs(:read).returns(valid_config.to_json)
      RedmineAiHelper::Util::ConfigurationMigrator.stubs(:migrate_config).returns(valid_config)
      
      # Mock tool class generation to raise an error
      error = StandardError.new("Tool generation failed")
      error.set_backtrace(["line1", "line2"])
      RedmineAiHelper::Tools::McpTools.stubs(:generate_tool_class).raises(error)
      
      # Mock logger with debug enabled
      mock_logger = mock('logger')
      mock_logger.expects(:error).with("Error generating tool class for test_server: Tool generation failed")
      mock_logger.stubs(:debug?).returns(true)
      mock_logger.expects(:respond_to?).with(:debug?).returns(true)
      mock_logger.expects(:error).with("line1\nline2")
      mock_logger.stubs(:warn)
      
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      loader.stubs(:ai_helper_logger).returns(mock_logger)
      loader.instance_variable_set(:@list, nil)
      
      tools = loader.generate_tools_instances
      assert_equal [], tools
    end

    should "skip invalid server configurations and log warnings" do
      config_with_invalid_server = {
        "mcpServers" => {
          "valid_server" => {
            "command" => "node",
            "args" => ["server.js"]
          },
          "invalid_server" => {
            # Missing required fields
          }
        }
      }
      
      # Mock file operations
      File.stubs(:exist?).returns(true)
      File.stubs(:read).returns(config_with_invalid_server.to_json)
      RedmineAiHelper::Util::ConfigurationMigrator.stubs(:migrate_config).returns(config_with_invalid_server)
      
      # Mock tool class generation for valid server only
      mock_tool_class = Class.new
      RedmineAiHelper::Tools::McpTools.expects(:generate_tool_class)
        .with(name: "valid_server", json: config_with_invalid_server["mcpServers"]["valid_server"])
        .returns(mock_tool_class)
      
      # Mock logger
      mock_logger = mock('logger')
      mock_logger.expects(:warn).with("Invalid configuration for MCP server 'invalid_server': #{config_with_invalid_server["mcpServers"]["invalid_server"]}")
      mock_logger.expects(:info).with("Successfully loaded MCP server 'valid_server' with transport 'stdio'")
      mock_logger.stubs(:error)
      
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      loader.stubs(:ai_helper_logger).returns(mock_logger)
      loader.instance_variable_set(:@list, nil)
      
      tools = loader.generate_tools_instances
      assert_equal [mock_tool_class], tools
    end

    should "validate stdio configuration with args only" do
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      
      # Valid: has args but no command
      config_with_args_only = { 'args' => ['server.js'] }
      assert loader.send(:valid_server_config?, config_with_args_only)
      
      # Valid: has both command and args
      config_with_both = { 'command' => 'node', 'args' => ['server.js'] }
      assert loader.send(:valid_server_config?, config_with_both)
      
      # Invalid: empty args array
      config_with_empty_args = { 'args' => [] }
      assert_equal false, loader.send(:valid_server_config?, config_with_empty_args)
    end

    should "validate http configuration with various URLs" do
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      
      # Valid HTTP URLs
      valid_http_config = { 'url' => 'http://localhost:3000' }
      assert loader.send(:valid_server_config?, valid_http_config)
      
      valid_https_config = { 'url' => 'https://example.com/api' }
      assert loader.send(:valid_server_config?, valid_https_config)
      
      # Invalid URLs
      invalid_url_config = { 'url' => 'ftp://example.com' }
      assert_equal false, loader.send(:valid_server_config?, invalid_url_config)
      
      malformed_url_config = { 'url' => 'not-a-url' }
      assert_equal false, loader.send(:valid_server_config?, malformed_url_config)
    end

    should "handle explicit transport configuration" do
      loader = RedmineAiHelper::Util::McpToolsLoader.instance
      
      # Explicit stdio transport
      stdio_config = { 'transport' => 'stdio', 'command' => 'node' }
      assert loader.send(:valid_server_config?, stdio_config)
      
      # Explicit http transport
      http_config = { 'transport' => 'http', 'url' => 'http://localhost:3000' }
      assert loader.send(:valid_server_config?, http_config)
      
      # Invalid transport type
      invalid_transport_config = { 'transport' => 'invalid', 'command' => 'node' }
      assert_equal false, loader.send(:valid_server_config?, invalid_transport_config)
    end
  end
end