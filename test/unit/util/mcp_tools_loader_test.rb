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
  end
end