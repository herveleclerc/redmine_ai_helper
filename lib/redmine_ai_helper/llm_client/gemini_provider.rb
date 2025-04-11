module RedmineAiHelper
  module LlmClient
    class GeminiProvider < RedmineAiHelper::LlmClient::BaseProvider
      def generate_client
        model_profile = AiHelperSetting.find_or_create.model_profile
        raise "Model Profile not found" unless model_profile
        client = Langchain::LLM::GoogleGemini.new(
          api_key: model_profile.access_key,
          default_options: {
            chat_model: model_profile.llm_model,
            temperature: 0.5,
          },
        )
        raise "Gemini LLM Create Error" unless client
        client
      end

      def create_chat_param(system_prompt, messages)
        new_messages = messages.map do |message|
          {
            role: message[:role],
            parts: [
              {
                text: message[:content],
              },
            ],
          }
        end
        chat_params = {
          messages: new_messages,
          system: system_prompt[:content],
        }
        chat_params
      end

      def reset_assistant_messages(assistant:, system_prompt:, messages:)
        assistant.clear_messages!
        assistant.instructions = system_prompt
        messages.each do |message|
          role = message[:role]
          role = "model" if role == "assistant"
          assistant.add_message(role: role, content: message[:content])
        end
      end
    end
  end
end
