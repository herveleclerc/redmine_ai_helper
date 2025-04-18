require "langchain"
require "redmine_ai_helper/logger"

module RedmineAiHelper

  # Base class for tool definitions used by the Agent
  class BaseTools
    extend Langchain::ToolDefinition

    include RedmineAiHelper::Logger
    include Rails.application.routes.url_helpers

    # Utility function to check if User.current has access to the specified project
    # @param project [Project] the project to check
    # @return [Boolean] true if the user has access to the project, false otherwise
    def accessible_project?(project)
      return false unless project.visible?
      return false unless project.module_enabled?(:ai_helper)
      User.current.allowed_to?({ controller: :ai_helper, action: :chat_form }, project)
    end
  end
end
