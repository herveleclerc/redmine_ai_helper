module RedmineAiHelper
  module LlmClient
    class AnthropicProvider < RedmineAiHelper::LlmProvider
      def generate_client
        client = Langchain::LLM::Anthropic.new(
          api_key: config["access_token"],
          default_options: {
            chat_model: config["model"],
            temperature: 0.5,
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
      end

      def dig_keyword
        "text"
      end
    end
  end
end
