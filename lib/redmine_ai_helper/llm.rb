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
        langfuse.create_span(name: "user request", input: task)
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
  end
end
