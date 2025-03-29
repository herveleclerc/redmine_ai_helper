require "redmine_ai_helper/base_tool_provider"

module RedmineAiHelper
  module Tools
    class SystemToolProvider < RedmineAiHelper::BaseToolProvider
      define_function :list_plugins, description: "Returns a list of all plugins installed in Redmine." do
        property :dummy, type: "string", description: "Dummy property. No need to specify.", required: false
      end
      # Returns a list of all plugins installed in Redmine
      def list_plugins(dummy: nil)
        plugins = Redmine::Plugin.all
        plugin_list = []
        plugins.map do |plugin|
          plugin_list <<
          {
            name: plugin.name,
            version: plugin.version,
            author: plugin.author,
            url: plugin.url,
            author_url: plugin.author_url,
          }
        end
        json = { plugins: plugin_list }
        tool_response(content: json)
      end
    end
  end
end
