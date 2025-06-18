# frozen_string_literal: true
require_relative "logger"
require_relative "base_agent"
require_relative "langfuse_util/langfuse_wrapper"

module RedmineAiHelper

  # A class that is directly called from the controller to interact with AI using LLM.
  # TODO: クラス名を変えたい
  class Llm
    include RedmineAiHelper::Logger
    attr_accessor :model

    def initialize(params = {})
    end

    # chat with the AI
    # @param conversation [Conversation] The conversation object
    # @param proc [Proc] A block to be executed after the task is sent
    # @param option [Hash] Options for the task
    # @return [AiHelperMessage] The AI's response
    def chat(conversation, proc, option = {})
      task = conversation.messages.last.content
      ai_helper_logger.debug "#### ai_helper: chat start ####"
      ai_helper_logger.info "user:#{User.current}, task: #{task}, option: #{option}"
      begin
        langfuse = RedmineAiHelper::LangfuseUtil::LangfuseWrapper.new(input: task)
        option[:langfuse] = langfuse
        agent = RedmineAiHelper::Agents::LeaderAgent.new(option)
        langfuse.create_span(name: "user_request", input: task)
        answer = agent.perform_user_request(conversation.messages_for_openai, option, proc)
        langfuse.finish_current_span(output: answer)
        langfuse.flush
      rescue => e
        ai_helper_logger.error "error: #{e.full_message}"
        answer = e.message
      end
      ai_helper_logger.info "answer: #{answer}"
      AiHelperMessage.new(role: "assistant", content: answer, conversation: conversation)
    end

    # Get the summary of the issue using IssueAgent
    # @param issue [Issue] The issue object
    # return [String] The summary of the issue
    def issue_summary(issue:)
      begin
        prompt = "Please summarize the issue #{issue.id}."
        langfuse = RedmineAiHelper::LangfuseUtil::LangfuseWrapper.new(input: prompt)
        agent = RedmineAiHelper::Agents::IssueAgent.new(project: issue.project, langfuse: langfuse)
        langfuse.create_span(name: "user_request", input: prompt)
        answer = agent.issue_summary(issue: issue)
        langfuse.finish_current_span(output: answer)
        langfuse.flush
      rescue => e
        ai_helper_logger.error "error: #{e.full_message}"
        answer = e.message
      end
      ai_helper_logger.info "answer: #{answer}"
      answer
    end

    # Generate a reply to the issue using IssueAgent with streaming support
    # @param issue [Issue] The issue object
    # @param instructions [String] Instructions for generating the reply
    # @param stream_proc [Proc] Optional callback proc for streaming content
    # return [String] The generated reply
    def generate_issue_reply(issue:, instructions:, stream_proc: nil)
      begin
        prompt = "Please generate a reply to the issue #{issue.id} with the instructions.\n\n#{instructions}"
        langfuse = RedmineAiHelper::LangfuseUtil::LangfuseWrapper.new(input: prompt)
        agent = RedmineAiHelper::Agents::IssueAgent.new(project: issue.project, langfuse: langfuse)
        langfuse.create_span(name: "user_request", input: prompt)
        
        answer = agent.generate_issue_reply(issue: issue, instructions: instructions, stream_proc: stream_proc)
        
        langfuse.finish_current_span(output: answer)
        langfuse.flush
      rescue => e
        ai_helper_logger.error "error: #{e.full_message}"
        answer = e.message
        stream_proc.call(answer) if stream_proc
      end
      ai_helper_logger.info "answer: #{answer}"
      answer
    end

    # Generate sub issues using IssueAgent
    # @param issue [Issue] The issue object
    # @param instructions [String] Instructions for generating sub issues
    # return [Array<Issue>] The generated sub issues
    def generate_sub_issues(issue:, instructions: nil)
      begin
        prompt = "Please generate sub issues for the issue #{issue.id} with the instructions.\n\n#{instructions}"
        langfuse = RedmineAiHelper::LangfuseUtil::LangfuseWrapper.new(input: prompt)
        agent = RedmineAiHelper::Agents::IssueAgent.new(project: issue.project, langfuse: langfuse)
        langfuse.create_span(name: "user_request", input: prompt)
        sub_issues = agent.generate_sub_issues_draft(issue: issue, instructions: instructions)
        langfuse.finish_current_span(output: sub_issues.inspect)
        langfuse.flush
      rescue => e
        ai_helper_logger.error "error: #{e.full_message}"
        throw e
      end
      ai_helper_logger.info "sub issues: #{sub_issues.inspect}"
      sub_issues
    end

    # Get the summary of the wiki page using WikiAgent
    # @param wiki_page [WikiPage] The wiki page object
    # return [String] The summary of the wiki page
    def wiki_summary(wiki_page:)
      begin
        prompt = "Please summarize the wiki page '#{wiki_page.title}'."
        langfuse = RedmineAiHelper::LangfuseUtil::LangfuseWrapper.new(input: prompt)
        agent = RedmineAiHelper::Agents::WikiAgent.new(project: wiki_page.wiki.project, langfuse: langfuse)
        langfuse.create_span(name: "user_request", input: prompt)
        answer = agent.wiki_summary(wiki_page: wiki_page)
        langfuse.finish_current_span(output: answer)
        langfuse.flush
      rescue => e
        ai_helper_logger.error "error: #{e.full_message}"
        answer = e.message
      end
      ai_helper_logger.info "answer: #{answer}"
      answer
    end
  end
end
