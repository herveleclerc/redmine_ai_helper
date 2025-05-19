# frozen_string_literal: true
module RedmineAiHelper
  # Hook to display the chat screen in the sidebar
  class ViewHook < Redmine::Hook::ViewListener
    render_on :view_layouts_base_html_head, :partial => "ai_helper/html_header"
    render_on :view_layouts_base_body_top, :partial => "ai_helper/sidebar"
    render_on :view_issues_show_details_bottom, :partial => "ai_helper/issue_bottom"
  end
end
