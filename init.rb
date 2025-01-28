$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require_dependency "redmine_ai_helper/sidebar_hook"
Redmine::Plugin.register :redmine_ai_helper do
  name "Redmine Ai Helper plugin"
  author "Haruyuki Iida"
  description "This plugin adds an AI assistant to Redmine."
  version "0.0.2"
  url "https://github.com/haru/redmine_ai_helper"
  author_url "https://github.com/haru"
  requires_redmine :version_or_higher => "6.0.0"

  project_module :ai_helper do
    permission :view_ai_helper, { ai_helper: [:chat, :chat_form, :reload, :clear, :call_llm] }
  end

  settings default: { 'model': "gpt-4o-mini" }, partial: "ai_helper/settings"
end
