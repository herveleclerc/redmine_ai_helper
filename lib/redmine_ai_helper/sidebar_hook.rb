module RedmineAiHelper
  class SidebarHook < Redmine::Hook::ViewListener
    # render_on :view_issues_sidebar_planning_bottom, partial: "ai_helper/sidebar"
    # render_on :view_layouts_base_sidebar, partial: "ai_helper/sidebar"
    render_on :view_layouts_base_html_head, :partial => "ai_helper/html_header"
    render_on :view_layouts_base_body_bottom, :partial => "ai_helper/sidebar"
  end
end
