require_relative "logger"
require_relative "base_agent"



module RedmineAiHelper
  class Llm
    include RedmineAiHelper::Logger
    attr_accessor :model

    # initialize the client
    # @param [Hash] params
    # @option params [String] :access_token
    # @option params [String] :uri_base
    # @option params [String] :organization_id
    def initialize(params = {})

      ai_helper_logger = ai_helper_logger
    end

    # chat with the AI
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
