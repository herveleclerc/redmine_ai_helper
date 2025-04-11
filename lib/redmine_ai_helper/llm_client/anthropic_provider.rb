module RedmineAiHelper
  module LlmClient
    class AnthropicProvider < RedmineAiHelper::LlmClient::BaseProvider
      def generate_client
        model_profile = AiHelperSetting.find_or_create.model_profile
        raise "Model Profile not found" unless model_profile
        client = Langchain::LLM::Anthropic.new(
          api_key: model_profile.access_key,
          default_options: {
            chat_model: model_profile.llm_model,
            temperature: 0.5,
            max_tokens: 2000,
          },
        )
        raise "Anthropic LLM Create Error" unless client
        client
      end

      def create_chat_param(system_prompt, messages)
        new_messages = messages.dup
        chat_params = {
          messages: new_messages,
        }
        chat_params[:system] = system_prompt[:content]
        chat_params
      end

      def chunk_converter(chunk)
        chunk.dig("delta", "text")
      end

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
