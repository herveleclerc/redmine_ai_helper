# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  post "projects/:id/ai_helper/chat", to: "ai_helper#chat", as: "ai_helper_chat"
  get "projects/:id/ai_helper/chat_form", to: "ai_helper#chat_form", as: "ai_helper_chat_form"
  get "projects/:id/ai_helper/reload", to: "ai_helper#reload", as: "ai_helper_reload"
  get "projects/:id/ai_helper/clear", to: "ai_helper#clear", as: "ai_helper_clear"
  get "projects/:id/ai_helper/history", to: "ai_helper#history", as: "ai_helper_history"
  get "projects/:id/ai_helper/conversation/:conversation_id", to: "ai_helper#conversation", as: "ai_helper_conversation"
  delete "projects/:id/ai_helper/conversation/:conversation_id", to: "ai_helper#conversation", as: "ai_helper_delete_conversation"
  post "projects/:id/ai_helper/call_llm", to: "ai_helper#call_llm", as: "ai_helper_call_llm"
  get "ai_helper/issue/:id/summary", to: "ai_helper#issue_summary", as: "ai_helper_issue_summary"

  get "ai_helper_settings/index", to: "ai_helper_settings#index", as: "ai_helper_setting"
  post "ai_helper_settings/index", to: "ai_helper_settings#update", as: "ai_helper_setting_update"

  get "ai_helper_model_profiles", to: "ai_helper_model_profiles#index", as: "ai_helper_model_profiles"
  get "ai_helper_model_profiles/:id", to: "ai_helper_model_profiles#show", as: "ai_helper_model_profiles_show"
  get "ai_helper_model_profiles/:id/edit", to: "ai_helper_model_profiles#edit", as: "ai_helper_model_profiles_edit"
  get "ai_helper_model_profiles_new", to: "ai_helper_model_profiles#new", as: "ai_helper_model_profiles_new"
  post "ai_helper_model_profiles", to: "ai_helper_model_profiles#create", as: "ai_helper_model_profiles_create"
  post "ai_helper_model_profiles/:id/edit", to: "ai_helper_model_profiles#update", as: "ai_helper_model_profiles_update"
  delete "ai_helper_model_profiles/:id", to: "ai_helper_model_profiles#destroy", as: "ai_helper_model_profiles_destroy"
end
