$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require_dependency "redmine_ai_helper/sidebar_hook"
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

  version "0.2.4"

  project_module :ai_helper do
    permission :view_ai_helper, { ai_helper: [:chat, :chat_form, :reload, :clear, :call_llm, :history, :conversation] }
  end

  settings default: { 'model': "gpt-4o-mini" }, partial: "ai_helper/settings"
end
