$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"
require_dependency 'redmine_ai_helper/sidebar_hook'
Redmine::Plugin.register :redmine_ai_helper do
  name 'Redmine Ai Helper plugin'
  author 'Haruyuki Iida'
  description 'This is a plugin that helps you analyze issues with AI.'
  version '0.0.1'
  url 'https://github.com/haru/redmine_ai_helper'
  author_url 'http://example.com/about'

  project_module :ai_helper do
    permission :view_ai_helper, { ai_helper: [:chat, :chat_form, :reload] }
  end
end
