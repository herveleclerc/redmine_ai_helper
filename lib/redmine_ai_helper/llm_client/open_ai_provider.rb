require_relative "base_provider"
module RedmineAiHelper
  module LlmClient
    class OpenAiProvider < RedmineAiHelper::LlmClient::BaseProvider
      def generate_client
        model_profile = AiHelperSetting.find_or_create.model_profile
        raise "Model Profile not found" unless model_profile
        llm_options = {}
        llm_options[:organization_id] = model_profile.organization_id if model_profile.organization_id
        client = Langchain::LLM::OpenAI.new(
          api_key: model_profile.access_key,
          llm_options: llm_options,
          default_options: {
            chat_model: model_profile.llm_model,
            temperature: 0.5,
          },
        )
        raise "OpenAI LLM Create Erro" unless client
        client
      end

    end
  end
end
