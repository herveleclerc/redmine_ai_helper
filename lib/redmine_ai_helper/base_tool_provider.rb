require "langchain"
require "redmine_ai_helper/logger"

module RedmineAiHelper

  class BaseToolProvider
    extend Langchain::ToolDefinition

    include RedmineAiHelper::Logger
    include Rails.application.routes.url_helpers


    def accessible_project?(project)
      return false unless project.visible?
      return false unless project.module_enabled?(:ai_helper)
      User.current.allowed_to?({ controller: :ai_helper, action: :chat_form }, project)
    end

  end
end
