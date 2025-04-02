module RedmineAiHelper
  module LlmClient
    class OpenAiProvider < RedmineAiHelper::LlmProvider
      def generate_client
        llm_options = {}
        llm_options[:organization_id] = config["organization_id"] if config["organization_id"].present?
        client = Langchain::LLM::OpenAI.new(
          api_key: config["access_token"],
          llm_options: llm_options,
          default_options: {
            chat_model: config["model"],
            temperature: 0.5,
          },
        )
        raise "OpenAI LLM Create Erro" unless client
        client
      end

    end
  end
end
