# frozen_string_literal: true
require "redmine_ai_helper/base_tools"

module RedmineAiHelper
  module Tools
    # SystemTools is a specialized tool provider for handling system-related queries in Redmine.
    class SystemTools < RedmineAiHelper::BaseTools
      define_function :list_plugins, description: "Returns a list of all plugins installed in Redmine." do
        property :dummy, type: "string", description: "Dummy property. No need to specify.", required: false
      end

      # Returns a list of all plugins installed in Redmine.
      # A dummy property is defined because at least one property is required in the tool
      # definition for langchainrb.
      # @param dummy [String] Dummy property to satisfy the tool definition requirement.
      # @return [Array<Hash>] An array of hashes containing plugin information.
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
        return json
      end
    end
  end
end
