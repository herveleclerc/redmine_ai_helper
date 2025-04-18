module RedmineAiHelper
  # Hook to display the AI helper chat screen in the Redmine sidebar
  class SidebarHook < Redmine::Hook::ViewListener
    render_on :view_layouts_base_html_head, :partial => "ai_helper/html_header"
    render_on :view_layouts_base_body_top, :partial => "ai_helper/sidebar"
  end
end
