# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  post 'projects/:id/ai_helper/chat', to: 'ai_helper#chat', as: 'ai_helper_chat'
  get 'projects/:id/ai_helper/chat_form', to: 'ai_helper#chat_form', as: 'ai_helper_chat_form'
  get 'projects/:id/ai_helper/reload', to: 'ai_helper#reload', as: 'ai_helper_reload'
  get 'projects/:id/ai_helper/clear', to: 'ai_helper#clear', as: 'ai_helper_clear'
end
