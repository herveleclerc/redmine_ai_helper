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
    end
  end
end
