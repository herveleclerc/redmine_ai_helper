# frozen_string_literal: true
require 'test_helper'

class TransportFactoryTest < ActiveSupport::TestCase
  context 'TransportFactory' do
    should 'create STDIO transport for configuration with command' do
      config = { 'command' => 'npx' }
      factory = RedmineAiHelper::Transport::TransportFactory
      
      transport = factory.create(config)
      assert_instance_of RedmineAiHelper::Transport::StdioTransport, transport
    end

    should 'create HTTP transport for configuration with URL' do
      config = { 'url' => 'http://localhost:3000' }
      factory = RedmineAiHelper::Transport::TransportFactory
      
      transport = factory.create(config)
      assert_instance_of RedmineAiHelper::Transport::HttpSseTransport, transport
    end

    should 'create STDIO transport for configuration with args only' do
      config = { 'args' => ['node', 'server.js'] }
      factory = RedmineAiHelper::Transport::TransportFactory
      
      transport = factory.create(config)
      assert_instance_of RedmineAiHelper::Transport::StdioTransport, transport
    end

    should 'auto-detect STDIO transport from command presence' do
      config = { 'command' => 'node', 'args' => ['server.js'] }
      factory = RedmineAiHelper::Transport::TransportFactory
      
      transport_type = factory.determine_transport_type(config)
      assert_equal 'stdio', transport_type
    end

    should 'auto-detect HTTP transport from URL presence' do
      config = { 'url' => 'http://localhost:3000' }
      factory = RedmineAiHelper::Transport::TransportFactory
      
      transport_type = factory.determine_transport_type(config)
      assert_equal 'http', transport_type
    end

    should 'raise error for configuration without command or URL' do
      config = { 'timeout' => 30 } # Neither command nor URL
      factory = RedmineAiHelper::Transport::TransportFactory
      
      assert_raises(ArgumentError, /Cannot determine transport type/) do
        factory.create(config)
      end
    end

    should 'raise error for empty configuration' do
      factory = RedmineAiHelper::Transport::TransportFactory
      
      assert_raises(ArgumentError, /Configuration is empty/) do
        factory.create({})
      end
    end

    should 'raise error for non-hash configuration' do
      factory = RedmineAiHelper::Transport::TransportFactory
      
      assert_raises(ArgumentError, /Configuration must be a hash/) do
        factory.create('invalid')
      end
    end
  end

  context 'configuration validation' do
    should 'validate STDIO configuration correctly' do
      factory = RedmineAiHelper::Transport::TransportFactory
      
      valid_configs = [
        { 'command' => 'npx' },
        { 'args' => ['node', 'server.js'] },
        { 'command' => 'node', 'args' => ['--version'] }
      ]
      
      valid_configs.each do |config|
        assert factory.valid_config?(config), "Should be valid: #{config}"
      end
    end

    should 'validate HTTP configuration correctly' do
      factory = RedmineAiHelper::Transport::TransportFactory
      
      valid_configs = [
        { 'url' => 'http://localhost:3000' },
        { 'url' => 'https://api.example.com' }
      ]
      
      valid_configs.each do |config|
        assert factory.valid_config?(config), "Should be valid: #{config}"
      end
    end

    should 'reject invalid configurations' do
      factory = RedmineAiHelper::Transport::TransportFactory
      
      invalid_configs = [
        { 'url' => 'invalid-url' },
        { 'timeout' => 30 }, # Neither command nor URL
        {},
        nil,
        'string',
        []
      ]
      
      invalid_configs.each do |config|
        assert_not factory.valid_config?(config), "Should be invalid: #{config}"
      end
    end
  end

  context 'supported transports' do
    should 'return list of supported transport types' do
      factory = RedmineAiHelper::Transport::TransportFactory
      supported = factory.supported_transports
      
      assert_includes supported, 'stdio'
      assert_includes supported, 'http'
      assert_equal 2, supported.length
    end
  end

  context 'instance methods' do
    should 'work as instance methods too' do
      factory = RedmineAiHelper::Transport::TransportFactory.new
      config = { 'transport' => 'stdio', 'command' => 'echo' }
      
      transport = factory.create(config)
      assert_instance_of RedmineAiHelper::Transport::StdioTransport, transport
      
      assert_equal 'stdio', factory.determine_transport_type(config)
      assert factory.valid_config?(config)
      assert_includes factory.supported_transports, 'stdio'
    end
  end

  context 'edge cases' do
    should 'prioritize URL over command when both present' do
      config = {
        'command' => 'node',
        'url' => 'http://localhost:3000' # URL takes precedence
      }
      factory = RedmineAiHelper::Transport::TransportFactory
      
      transport = factory.create(config)
      assert_instance_of RedmineAiHelper::Transport::HttpSseTransport, transport
    end

    should 'raise error for configuration without clear transport indicators' do
      config = { 'timeout' => 30 } # No command or URL
      factory = RedmineAiHelper::Transport::TransportFactory
      
      assert_raises(ArgumentError, /Cannot determine transport type/) do
        factory.determine_transport_type(config)
      end
    end

    should 'handle legacy configuration format' do
      # Legacy format without explicit transport
      config = {
        'command' => 'npx',
        'args' => ['-y', '@modelcontextprotocol/server-slack'],
        'env' => { 'SLACK_BOT_TOKEN' => 'token' }
      }
      factory = RedmineAiHelper::Transport::TransportFactory
      
      transport = factory.create(config)
      assert_instance_of RedmineAiHelper::Transport::StdioTransport, transport
    end
  end
end