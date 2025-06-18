#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

begin
  require 'redmine_ai_helper/transport/base_transport'
  puts "✓ BaseTransport loaded successfully"
  
  require 'redmine_ai_helper/transport/stdio_transport'
  puts "✓ StdioTransport loaded successfully"
  
  require 'redmine_ai_helper/transport/transport_factory'
  puts "✓ TransportFactory loaded successfully"
  
  # Test factory creation
  stdio_config = { 'command' => 'echo', 'args' => ['test'] }
  transport = RedmineAiHelper::Transport::TransportFactory.create(stdio_config)
  puts "✓ Factory created transport: #{transport.class.name}"
  
  puts "\nAll transport classes loaded and working correctly!"
  
rescue => e
  puts "✗ Error loading transport classes: #{e.message}"
  puts "  #{e.backtrace.first}"
end