# This controller is responsible for handling the chat messages between the user and the AI.
# require 'ai_helper_conversation'
# require 'ai_helper_message'

class AiHelperController < ApplicationController
  before_action :find_user, :find_project, :authorize, :create_session, :find_conversation
  def chat_form
    @message = AiHelperMessage.new
    render partial: 'ai_helper/chat_form'
  end

  def reload
    render partial: 'ai_helper/chat'
  end

  def chat
    @message = AiHelperMessage.new
    unless @conversation.id
      @conversation.title = "Chat with AI"
      @conversation.save!
      set_conversation_id(@conversation.id)
    end
    @message.conversation = @conversation
    @message.role = 'user'
    @message.content = params[:ai_helper_message][:content]
    @message.save!
    render partial: 'ai_helper/chat'
  end

  private

  def find_user
    @user = User.current
  end

  def create_session
    session[:ai_helper] ||= {}
    session[:ai_helper][@project.identifier] ||= {}
  end

  def conversation_id
    session[:ai_helper][@project.identifier][:conversation_id]
  end

  def set_conversation_id(id)
    session[:ai_helper][@project.identifier][:conversation_id] = id
  end

  def find_conversation
    session[:ai_helper] ||= {}
    if conversation_id
      @conversation = AiHelperConversation.find(conversation_id)
    else
      @conversation = AiHelperConversation.new
      @conversation.user = @user
    end
  end
end
