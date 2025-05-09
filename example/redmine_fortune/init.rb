require_relative "./fortune_agent" # Don't forget to require the agent class

Redmine::Plugin.register :redmine_fortune do
  name "Redmine Fortune plugin"
  author "Haruyuki Iida"
  description "This is a example plugin of AI Agent for Redmine AI Helper"
  version "0.0.1"
  url "https://github.com/haru/redmine_ai_helper"
  author_url "https://github.com/haru"
end
