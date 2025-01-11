module RedmineAiHelper
  class << self
    class SidebarHook < Redmine::Hook::ViewListener
      render_on :view_issues_sidebar_planning_bottom, partial: 'ai_helper/sidebar'
    end
  end
end
