# This controller is responsible for handling the chat messages between the user and the AI.
# require 'ai_helper_conversation'
# require 'ai_helper_message'
require "redmine_ai_helper/llm"

class AiHelperController < ApplicationController
  before_action :find_user, :find_project, :authorize, :create_session, :find_conversation

  def chat_form
    @message = AiHelperMessage.new
    render partial: "ai_helper/chat_form"
  end

  def reload
    render partial: "ai_helper/chat"
  end

  def chat
    @message = AiHelperMessage.new
    unless @conversation.id
      @conversation.title = "Chat with AI"
      @conversation.save!
      set_conversation_id(@conversation.id)
    end
    @message.conversation = @conversation
    @message.role = "user"
    @message.content = params[:ai_helper_message][:content]
    @message.save!
    @conversation = AiHelperConversation.find(@conversation.id)
    render partial: "ai_helper/chat"
  end

  def call_llm
    contoller_name = params[:controller_name]
    action_name = params[:action_name]
    content_id = params[:content_id].to_i unless params[:content_id].blank?
    llm = RedmineAiHelper::Llm.new
    option = {
      controller_name: contoller_name,
      action_name: action_name,
      content_id: content_id,
      project: @project,
    }
    @conversation.messages << llm.chat(@conversation, option)
    @conversation.save!
    render partial: "ai_helper/chat"
  end

  def clear
    session[:ai_helper] = {}
    find_conversation
    render partial: "ai_helper/chat"
  end

  private

  def find_user
    @user = User.current
  end

  def create_session
    session[:ai_helper] ||= {}
  end

  def conversation_id
    session[:ai_helper][:conversation_id]
  end

  def set_conversation_id(id)
    session[:ai_helper][:conversation_id] = id
  end

  def find_conversation
    if conversation_id
      @conversation = AiHelperConversation.find(conversation_id)
    else
      @conversation = AiHelperConversation.new
      @conversation.user = @user
    end
  end
end
