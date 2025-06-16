# frozen_string_literal: true
require 'test_helper'

class BaseTransportTest < ActiveSupport::TestCase
  def setup
    @config = { 'test' => 'value' }
    @transport = RedmineAiHelper::Transport::BaseTransport.new(@config)
  end

  context 'BaseTransport initialization' do
    should 'accept valid configuration' do
      config = { 'url' => 'http://localhost:3000' }
      transport = RedmineAiHelper::Transport::BaseTransport.new(config)
      assert_equal config, transport.config
    end

    should 'raise error for non-hash configuration' do
      assert_raises(ArgumentError, 'Configuration must be a hash') do
        RedmineAiHelper::Transport::BaseTransport.new('invalid')
      end
    end

    should 'raise error for nil configuration' do
      assert_raises(ArgumentError) do
        RedmineAiHelper::Transport::BaseTransport.new(nil)
      end
    end
  end

  context 'abstract methods' do
    should 'raise NotImplementedError for send_request' do
      message = { 'method' => 'test' }
      assert_raises(NotImplementedError) do
        @transport.send_request(message)
      end
    end

    should 'raise NotImplementedError for close' do
      assert_raises(NotImplementedError) do
        @transport.close
      end
    end

    should 'allow connect method (default implementation)' do
      # Should not raise error
      assert_nothing_raised do
        @transport.connect
      end
    end
  end

  context 'transport type detection' do
    should 'return correct transport type' do
      assert_equal 'base', @transport.transport_type
    end
  end

  context 'JSON-RPC utilities' do
    should 'generate unique request IDs' do
      id1 = @transport.send(:generate_request_id)
      id2 = @transport.send(:generate_request_id)
      
      assert_not_equal id1, id2
      assert id1 > 0
      assert id2 > id1
    end

    should 'build proper JSON-RPC message' do
      message = @transport.send(:build_jsonrpc_message, 'test_method', { 'param' => 'value' }, 123)
      
      assert_equal '2.0', message['jsonrpc']
      assert_equal 'test_method', message['method']
      assert_equal({ 'param' => 'value' }, message['params'])
      assert_equal 123, message['id']
    end

    should 'auto-generate ID if not provided' do
      message = @transport.send(:build_jsonrpc_message, 'test_method')
      
      assert_not_nil message['id']
      assert message['id'] > 0
    end
  end

  context 'response parsing' do
    should 'parse successful response' do
      response_text = {
        'jsonrpc' => '2.0',
        'id' => 1,
        'result' => { 'data' => 'success' }
      }.to_json
      
      result = @transport.send(:parse_response, response_text)
      assert_equal 'success', result.dig('result', 'data')
    end

    should 'raise error for error response' do
      response_text = {
        'jsonrpc' => '2.0',
        'id' => 1,
        'error' => {
          'code' => -32600,
          'message' => 'Invalid request'
        }
      }.to_json
      
      assert_raises(StandardError, 'MCP Error (-32600): Invalid request') do
        @transport.send(:parse_response, response_text)
      end
    end

    should 'raise error for invalid JSON' do
      response_text = 'invalid json'
      
      assert_raises(StandardError, /Invalid JSON response/) do
        @transport.send(:parse_response, response_text)
      end
    end
  end
end