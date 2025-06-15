# frozen_string_literal: true
# This controller is responsible for handling the chat messages between the user and the AI.
require "redmine_ai_helper/llm"
require "redmine_ai_helper/logger"

class AiHelperController < ApplicationController
  include ActionController::Live
  include RedmineAiHelper::Logger
  include AiHelperHelper

  before_action :find_issue, only: [:issue_summary, :update_issue_summary, :generate_issue_reply, :generate_sub_issues, :add_sub_issues]
  before_action :find_wiki_page, only: [:wiki_summary]
  before_action :find_project, except: [:issue_summary, :wiki_summary, :generate_issue_reply, :generate_sub_issues, :add_sub_issues]
  before_action :find_user, :authorize, :create_session, :find_conversation

  # Display the chat form in the sidebar
  def chat_form
    @message = AiHelperMessage.new
    render partial: "ai_helper/chat_form"
  end

  # Redisplay the chat screen
  def reload
    render partial: "ai_helper/chat"
  end

  # Reflect the message entered in the chat form on the chat screen
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

  # Load the specified conversation
  # If the request is a delete request, delete the conversation
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

  # Display the conversation history
  def history
    @conversations = AiHelperConversation.where(user: @user).order(updated_at: :desc).limit(10)
    render partial: "ai_helper/history"
  end

  # Display the issue summary
  def issue_summary
    summary = AiHelperSummaryCache.issue_cache(issue_id: @issue.id)
    if params[:update] == "true" && summary
      summary.destroy!
      summary = nil
    end
    llm = RedmineAiHelper::Llm.new
    unless summary
      content = llm.issue_summary(issue: @issue)
      summary = AiHelperSummaryCache.update_issue_cache(issue_id: @issue.id, content: content)
    end

    render partial: "ai_helper/issue_summary", locals: { summary: summary }
  end

  # Display the wiki summary
  def wiki_summary
    summary = AiHelperSummaryCache.wiki_cache(wiki_page_id: @wiki_page.id)
    if params[:update] == "true" && summary
      summary.destroy!
      summary = nil
    end
    llm = RedmineAiHelper::Llm.new
    unless summary
      content = llm.wiki_summary(wiki_page: @wiki_page)
      summary = AiHelperSummaryCache.update_wiki_cache(wiki_page_id: @wiki_page.id, content: content)
    end

    render partial: "ai_helper/wiki_summary_content", locals: { summary: summary }
  end

  # Call the LLM and stream the response
  def call_llm
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Connection"] = "keep-alive"
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

    response_id = "chatcmpl-#{SecureRandom.hex(12)}"

    write_chunk({
      id: response_id,
      object: "chat.completion.chunk",
      created: Time.now.to_i,
      model: "gpt-3.5-turbo-0613",
      choices: [{
        index: 0,
        delta: {
          role: "assistant",
        },
        finish_reason: nil,
      }],
    })

    proc = Proc.new do |content|
      write_chunk({
        id: response_id,
        object: "chat.completion.chunk",
        created: Time.now.to_i,
        model: "gpt-3.5-turbo-0613",
        choices: [{
          index: 0,
          delta: {
            content: content,
          },
          finish_reason: nil,
        }],
      })
    end

    @conversation.messages << llm.chat(@conversation, proc, option)
    @conversation.save!

    write_chunk({
      id: response_id,
      object: "chat.completion.chunk",
      created: Time.now.to_i,
      model: "gpt-3.5-turbo-0613",
      choices: [{
        index: 0,
        delta: {},
        finish_reason: "stop",
      }],
    })
  ensure
    response.stream.close
  end

  # Clear the chat screen
  def clear
    session[:ai_helper] = {}
    find_conversation
    render partial: "ai_helper/chat"
  end

  # Receives a POST message with application/json content to generate an issue reply
  def generate_issue_reply
    unless request.content_type == "application/json"
      render json: { error: "Unsupported Media Type" }, status: :unsupported_media_type and return
    end

    begin
      data = JSON.parse(request.body.read)
    rescue JSON::ParserError
      render json: { error: "Invalid JSON" }, status: :bad_request and return
    end

    instructions = data["instructions"]
    llm = RedmineAiHelper::Llm.new

    reply = llm.generate_issue_reply(issue: @issue, instructions: instructions)

    render partial: "ai_helper/issue_reply", locals: { issue: @issue, reply: reply }
  end

  # Generate sub-issues drafts for the given issue
  def generate_sub_issues
    llm = RedmineAiHelper::Llm.new
    unless request.content_type == "application/json"
      render json: { error: "Unsupported Media Type" }, status: :unsupported_media_type and return
    end

    begin
      data = JSON.parse(request.body.read)
    rescue JSON::ParserError
      render json: { error: "Invalid JSON" }, status: :bad_request and return
    end

    instructions = data["instructions"]
    subissues = llm.generate_sub_issues(issue: @issue, instructions: instructions)

    trackers = @issue.allowed_target_trackers
    trackers = trackers.reject do |tracker|
      @issue.tracker_id != tracker.id && tracker.disabled_core_fields.include?("parent_issue_id")
    end
    trackers_options_for_select = trackers.collect { |t| [t.name, t.id] }

    versions = @issue.assignable_versions || []
    versions_options_for_select = versions.collect { |v| [v.name, v.id] }

    render partial: "ai_helper/subissue_gen/issues", locals: { issue: @issue, subissues: subissues, trackers_options_for_select: trackers_options_for_select, versions_options_for_select: versions_options_for_select }
  end

  # Add sub-issues to the current issue
  def add_sub_issues
    issues_param = params[:sub_issues]
    issues_param.each do |issue_param_array|
      issue_param = issue_param_array[1].permit(:subject, :description, :tracker_id, :check, :fixed_version_id)
      # Skip if the issue_param does not have the :check key or if it is false
      next unless issue_param[:check]
      issue = Issue.new
      issue.author = User.current
      issue.project = @issue.project
      issue.parent_id = @issue.id
      issue.subject = issue_param[:subject]
      issue.description = issue_param[:description]
      issue.tracker_id = issue_param[:tracker_id]
      issue.fixed_version_id = issue_param[:fixed_version_id] unless issue_param[:fixed_version_id].blank?
      # Save the issue and handle errors
      unless issue.save
        # If saving fails, collect error messages and display them using i18n
        flash[:error] = issue.errors.full_messages.join("\n")
        redirect_to issue_path(@issue) and return
      end
    end
    redirect_to issue_path(@issue), notice: l(:notice_sub_issues_added)
  end

  private

  # Find the user
  def find_user
    @user = User.current
  end

  # Create a hash to store AI helper information in the session
  def create_session
    session[:ai_helper] ||= {}
  end

  # Retrieve the current conversation ID from the session
  def conversation_id
    session[:ai_helper][:conversation_id]
  end

  # Set the conversation ID in the session
  def set_conversation_id(id)
    session[:ai_helper][:conversation_id] = id
  end

  # Retrieve the conversation from the session-stored conversation ID.
  # If the conversation does not exist, create a new one.
  def find_conversation
    if conversation_id
      @conversation = AiHelperConversation.find_by(id: conversation_id)
      return if @conversation
    end
    @conversation = AiHelperConversation.new
    @conversation.user = @user
  end

  # Write a chunk of data to the response stream
  def write_chunk(data)
    response.stream.write("data: #{data.to_json}\n\n")
  end

  # Find wiki page for wiki summary
  def find_wiki_page
    @wiki_page = WikiPage.find(params[:id])
    @project = @wiki_page.wiki.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
