# frozen_string_literal: true
require_dependency "projects_helper"

module RedmineAiHelper
  module ProjectsHelperPatch
    def project_settings_tabs
      tabs = super
      action = { :name => "ai_helper", :controller => "ai_helper_project_settings", :action => :show, :partial => "ai_helper_project_settings/show", :label => :label_ai_helper }

      tabs << action if User.current.allowed_to?(action, @project)

      tabs
    end
  end
end

ProjectsHelper.prepend(RedmineAiHelper::ProjectsHelperPatch)
