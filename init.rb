require "langfuse"
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require "redmine_ai_helper/util/config_file"
require "redmine_ai_helper/projects_helper_patch"
require "redmine_ai_helper/user_patch"
require_dependency "redmine_ai_helper/view_hook"
Dir[File.join(File.dirname(__FILE__), "lib/redmine_ai_helper/agents", "*_agent.rb")].each do |file|
  require file
end
Redmine::Plugin.register :redmine_ai_helper do
  name "Redmine Ai Helper plugin"
  author "Haruyuki Iida"
  description "This plugin adds an AI assistant to Redmine."
  url "https://github.com/haru/redmine_ai_helper"
  author_url "https://github.com/haru"
  requires_redmine :version_or_higher => "6.0.0"

  version "1.4.0"

  project_module :ai_helper do
    permission :view_ai_helper,
               { ai_helper: [
                 :chat, :chat_form, :reload, :clear, :call_llm,
                 :history, :issue_summary, :generate_issue_summary, :wiki_summary, :generate_wiki_summary, :conversation, :generate_issue_reply,
                 :generate_sub_issues, :add_sub_issues, :similar_issues,
               ] }
    permission :manage_ai_helper_settings, { ai_helper_project_settings: [:show, :update] }
  end

  menu :admin_menu, "icon ah_helper", {
         controller: "ai_helper_settings", action: "index",
       }, caption: :label_ai_helper, :icon => "ai-helper-robot",
          :plugin => :redmine_ai_helper
end
