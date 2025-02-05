# This controller is responsible for handling the chat messages between the user and the AI.
# require 'ai_helper_conversation'
# require 'ai_helper_message'
require "redmine_ai_helper/llm"
require "redmine_ai_helper/logger"

class AiHelperController < ApplicationController
  include ActionController::Live
  include RedmineAiHelper::Logger
  include AiHelperHelper
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

  def conversation
    if request.delete?
      conversation = AiHelperConversation.find(params[:conversation_id])
      need_reload = conversation.id == @conversation.id
      conversation.destroy!
      session[:ai_helper] = {} if need_reload
      return render json: { status: "ok", reload: need_reload }
    end
    @conversation = AiHelperConversation.find(params[:conversation_id])
    set_conversation_id(@conversation.id)
    reload
  end

  def history
    @conversations = AiHelperConversation.where(user: @user).order(updated_at: :desc).limit(10)
    render partial: "ai_helper/history"
  end

  def call_llm
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['Connection'] = 'keep-alive'
    contoller_name = params[:controller_name]
    action_name = params[:action_name]
    content_id = params[:content_id].to_i unless params[:content_id].blank?
    additional_info = {}
    params[:additional_info].each do |key, value|
      additional_info[key] = value
    end
    llm = RedmineAiHelper::Llm.new
    option = {
      controller_name: contoller_name,
      action_name: action_name,
      content_id: content_id,
      project: @project,
      additional_info: additional_info,
    }
    @conversation.messages << llm.chat(@conversation, option)
    @conversation.save!

    response_id = "chatcmpl-#{SecureRandom.hex(12)}"

    write_chunk({
      id: response_id,
      object: "chat.completion.chunk",
      created: Time.now.to_i,
      model: "gpt-3.5-turbo-0613",
      choices: [{
        index: 0,
        delta: {
          role: "assistant"
        },
        finish_reason: nil
      }]
    })

    buffer = ""
    @conversation.messages.last.content.each_char do |char|
      buffer += char
      if buffer.length >= 10 # 10文字ごとにチャンクを送信
        write_chunk({
          id: response_id,
          object: "chat.completion.chunk",
          created: Time.now.to_i,
          model: "gpt-3.5-turbo-0613",
          choices: [{
            index: 0,
            delta: {
              content: buffer
            },
            finish_reason: nil
          }]
        })
        buffer = ""
      end
      sleep 0.1 # Add a small delay between chunks
    end

    # 残りのバッファを送信
    unless buffer.empty?
      write_chunk({
        id: response_id,
        object: "chat.completion.chunk",
        created: Time.now.to_i,
        model: "gpt-3.5-turbo-0613",
        choices: [{
          index: 0,
          delta: {
            content: buffer
          },
          finish_reason: nil
        }]
      })
    end

    write_chunk({
      id: response_id,
      object: "chat.completion.chunk",
      created: Time.now.to_i,
      model: "gpt-3.5-turbo-0613",
      choices: [{
        index: 0,
        delta: {},
        finish_reason: "stop"
      }]
    })

  ensure
    response.stream.close
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

  def write_chunk(data)
    response.stream.write("data: #{data.to_json}\n\n")
  end
end
