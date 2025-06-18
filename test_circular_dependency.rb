#!/usr/bin/env ruby

# Test script to verify circular dependency is resolved

begin
  $LOAD_PATH.unshift(File.expand_path('lib', __dir__))
  
  puts "Testing transport module loading..."
  
  # This should load without circular dependency errors
  require 'redmine_ai_helper/transport'
  puts "✓ Main transport module loaded"
  
  # Test creating a transport
  config = { 'command' => 'echo', 'args' => ['test'] }
  transport = RedmineAiHelper::Transport.create(config)
  puts "✓ Transport created: #{transport.class.name}"
  
  puts "\nAll modules loaded successfully - circular dependency fixed!"
  
rescue NameError => e
  if e.message.include?("uninitialized constant") && e.message.include?("BaseTransport")
    puts "✗ Circular dependency still exists: #{e.message}"
    exit 1
  else
    puts "✗ Other NameError: #{e.message}"
    exit 1
  end
rescue => e
  puts "✗ Error: #{e.message}"
  puts "  #{e.backtrace.first}"
  exit 1
end