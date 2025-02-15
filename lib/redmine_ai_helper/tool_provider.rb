require "redmine_ai_helper/llm"
require "redmine_ai_helper/base_tool_provider"
require "redmine_ai_helper/logger"
require "redmine_ai_helper/tool_response"
# このソースファイルがあるディレクトリの下のtool_providers/*_provider.rbファイルをrequireする
Dir[File.join(File.dirname(__FILE__), "tool_providers", "*_provider.rb")].each do |file|
  require file
end

module RedmineAiHelper
  class ToolProvider
    include RedmineAiHelper::Logger

    def initialize(client, model)
      @client = client
      @model = model
    end

    def self.list_tools()
      list = {}

      providers = RedmineAiHelper::BaseToolProvider.provider_list.map do |provider|
        begin
          provider_class = Object.const_get(provider[:class])
          {
            name: provider[:name],
            tools: provider_class.send(:list_tools)[:tools],
          }
        rescue => e
          ai_helper_logger.error "provider = #{provider[:name]}: #{e.full_message}"
        end
      end
      list = { providers: providers }
      # json = JSON.pretty_generate(list)
    end

    def call_tool(params = {})
      provider = params[:provider]
      name = params[:name]
      args = params[:arguments]

      begin
        provider_class_name = RedmineAiHelper::BaseToolProvider.provider_class_name(provider)
        return ToolResponse.create_error "Provider not found.: #{provider}" if provider_class_name.nil?
        provider_instance = Object.const_get(provider_class_name).new()
      rescue => e
        ai_helper_logger.error "provider = #{provider}: #{e.full_message}"
        return ToolResponse.create_error "provider = #{provider}: #{e.message}"
      end

      # Use reflection to call the method named 'name' on this instance, passing 'args' as arguments.
      # If the method does not exist, an exception will be raised.
      if provider_instance.respond_to?(name)
        begin
          response = provider_instance.send(name, args)
        rescue => e
          ai_helper_logger.error e.full_message
          return ToolResponse.create_error e.message
        end
      else
        ai_helper_logger.error "provider = #{provider}: Method #{name} not found"
        return ToolResponse.create_error "provider = #{provider}: Method #{name} not found"
      end
      response
    end
  end
end
