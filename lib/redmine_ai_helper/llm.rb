require_relative "logger"
require_relative "base_agent"

module RedmineAiHelper
  # AiHelper LLM class
  # Called directly from the Controller, receives conversations from the user, queries the AI, and returns the response to the Controller.
  # @see AiHelperController
  # @see AiHelperConversation
  class Llm
    include RedmineAiHelper::Logger
    attr_accessor :model

    # initialize the client
    def initialize(params = {})
    end

    # Method called from the Controller
    # Pass the conversation to the LeaderAgent and receive a response from the AI.
    # @param conversation [AiHelperConversation] the conversation object
    # @param proc [Proc] Proc to receive the StreamingResponse from the LLM
    # @param option [Hash] the options for the LeaderAgent
    # @return [AiHelperMessage] the message object
    def chat(conversation, proc, option = {})
      task = conversation.messages.last.content
      ai_helper_logger.info "#### ai_helper: chat start ####"
      ai_helper_logger.info "user:#{User.current}, task: #{task}, option: #{option}"
      begin
        agent = RedmineAiHelper::Agents::LeaderAgent.new(option)
        answer = agent.perform_user_request(conversation.messages_for_openai, option, proc)
      rescue => e
        ai_helper_logger.error "error: #{e.full_message}"
        answer = e.message
      end
      ai_helper_logger.info "answer: #{answer}"
      AiHelperMessage.new(role: "assistant", content: answer, conversation: conversation)
    end
  end
end
