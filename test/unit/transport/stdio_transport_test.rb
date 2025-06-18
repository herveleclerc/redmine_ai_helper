# frozen_string_literal: true
require 'test_helper'

class StdioTransportTest < ActiveSupport::TestCase
  def setup
    @config = {
      'command' => 'echo',
      'args' => ['test'],
      'env' => { 'TEST_VAR' => 'value' }
    }
    @transport = RedmineAiHelper::Transport::StdioTransport.new(@config)
  end

  context 'StdioTransport initialization' do
    should 'accept valid command configuration' do
      config = { 'command' => 'npx', 'args' => ['-y', 'test-server'] }
      transport = RedmineAiHelper::Transport::StdioTransport.new(config)
      
      assert_equal ['npx', '-y', 'test-server'], transport.command_array
      assert_equal({}, transport.env_hash)
    end

    should 'accept configuration with only command' do
      config = { 'command' => 'node' }
      transport = RedmineAiHelper::Transport::StdioTransport.new(config)
      
      assert_equal ['node'], transport.command_array
    end

    should 'accept configuration with only args' do
      config = { 'args' => ['node', 'server.js'] }
      transport = RedmineAiHelper::Transport::StdioTransport.new(config)
      
      assert_equal ['node', 'server.js'], transport.command_array
    end

    should 'raise error for empty configuration' do
      assert_raises(ArgumentError, 'STDIO transport requires command or args') do
        RedmineAiHelper::Transport::StdioTransport.new({})
      end
    end

    should 'handle environment variables' do
      config = {
        'command' => 'test',
        'env' => { 'API_KEY' => 'secret' }
      }
      transport = RedmineAiHelper::Transport::StdioTransport.new(config)
      
      assert_equal({ 'API_KEY' => 'secret' }, transport.env_hash)
    end
  end

  context 'command array building' do
    should 'build proper command array from command and args' do
      assert_equal ['echo', 'test'], @transport.command_array
    end

    should 'handle command without args' do
      config = { 'command' => 'node' }
      transport = RedmineAiHelper::Transport::StdioTransport.new(config)
      
      assert_equal ['node'], transport.command_array
    end
  end

  context 'request sending' do
    should 'send request and parse response' do
      # Mock Open3.capture3 to return success
      mock_stdout = { 'jsonrpc' => '2.0', 'id' => 1, 'result' => { 'success' => true } }.to_json
      mock_status = stub(success?: true)
      
      Open3.stubs(:capture3).returns([mock_stdout, '', mock_status])
      
      message = { 'method' => 'test', 'params' => {}, 'id' => 1 }
      result = @transport.send_request(message)
      
      assert_equal true, result.dig('result', 'success')
    end

    should 'raise error on command failure' do
      mock_status = stub(success?: false)
      mock_stderr = 'Command failed'
      
      Open3.stubs(:capture3).returns(['', mock_stderr, mock_status])
      
      message = { 'method' => 'test' }
      
      assert_raises(RedmineAiHelper::Transport::StdioTransport::ExecutionError, /STDIO command execution error/) do
        @transport.send_request(message)
      end
    end

    should 'handle JSON parsing errors' do
      mock_stdout = 'invalid json'
      mock_status = stub(success?: true)
      
      Open3.stubs(:capture3).returns([mock_stdout, '', mock_status])
      
      message = { 'method' => 'test' }
      
      assert_raises(StandardError, /Invalid JSON response/) do
        @transport.send_request(message)
      end
    end
  end

  context 'connection management' do
    should 'always report as connected' do
      assert @transport.connected?
    end

    should 'allow close without error' do
      assert_nothing_raised do
        @transport.close
      end
    end
  end

  context 'call counter' do
    should 'increment call counter' do
      counter1 = @transport.call_counter_up
      counter2 = @transport.call_counter_up
      
      assert_equal 0, counter1
      assert_equal 1, counter2
    end
  end

  context 'MCP tool methods' do
    should 'load tools from server' do
      mock_response = {
        'jsonrpc' => '2.0',
        'id' => 1,
        'result' => {
          'tools' => [
            { 'name' => 'test_tool', 'description' => 'Test tool' }
          ]
        }
      }
      
      @transport.stubs(:send_request).returns(mock_response)
      
      tools = @transport.load_tools_from_server
      assert_equal 1, tools.length
      assert_equal 'test_tool', tools.first['name']
    end

    should 'return empty array on error' do
      @transport.stubs(:send_request).raises(StandardError.new('Connection failed'))
      
      tools = @transport.load_tools_from_server
      assert_equal [], tools
    end

    should 'call specific tool' do
      mock_response = {
        'jsonrpc' => '2.0',
        'id' => 1,
        'result' => { 'output' => 'tool result' }
      }
      
      @transport.stubs(:send_request).returns(mock_response)
      
      result = @transport.call_tool('test_tool', { 'param' => 'value' })
      assert_equal mock_response, result
    end
  end

  context 'statistics' do
    should 'provide transport statistics' do
      stats = @transport.stats
      
      assert_equal 'stdio', stats[:transport_type]
      assert_equal 'echo test', stats[:command]
      assert_equal 0, stats[:call_count]
      assert_equal true, stats[:connected]
    end
  end
end