# frozen_string_literal: true
module RedmineAiHelper
  module LlmClient
    ## AnthropicProvider is a specialized provider for handling requests to the Anthropic LLM.
    class AnthropicProvider < RedmineAiHelper::LlmClient::BaseProvider
      # generate a client for the Anthropic LLM
      # @return [Langchain::LLM::Anthropic] client
      def generate_client
        setting = AiHelperSetting.find_or_create
        model_profile = setting.model_profile
        raise "Model Profile not found" unless model_profile
        default_options = {
          chat_model: model_profile.llm_model,
          temperature: model_profile.temperature,
          max_tokens: 2000,
        }
        default_options[:max_tokens] = setting.max_tokens if setting.max_tokens
        client = RedmineAiHelper::LangfuseUtil::Anthropic.new(
          api_key: model_profile.access_key,
          default_options: default_options,
        )
        raise "Anthropic LLM Create Error" unless client
        client
      end

      # Generate a chat completion request
      # @param [Hash] system_prompt
      # @param [Array] messages
      # @return [Hash] chat_params
      def create_chat_param(system_prompt, messages)
        new_messages = messages.dup
        chat_params = {
          messages: new_messages,
        }
        chat_params[:system] = system_prompt[:content]
        chat_params
      end

      # Extract a message from the chunk
      # @param [Hash] chunk
      # @return [String] message
      def chunk_converter(chunk)
        chunk.dig("delta", "text")
      end

      # Clear the messages held by the Assistant, set the system prompt, and add messages
      # @param [RedmineAiHelper::Assistant] assistant
      # @param [Hash] system_prompt
      # @param [Array] messages
      # @return [void]
      def reset_assistant_messages(assistant:, system_prompt:, messages:)
        assistant.clear_messages!
        assistant.instructions = system_prompt
        messages.each do |message|
          assistant.add_message(role: message[:role], content: message[:content])
        end
      end
    end
  end
end
