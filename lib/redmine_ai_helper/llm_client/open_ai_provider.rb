# frozen_string_literal: true
require_relative "base_provider"

module RedmineAiHelper
  module LlmClient
    # OpenAiProvider is a specialized provider for handling OpenAI-related queries.
    class OpenAiProvider < RedmineAiHelper::LlmClient::BaseProvider
      # Generate a client for OpenAI LLM
      # @return [Langchain::LLM::OpenAI] the OpenAI client
      def generate_client
        setting = AiHelperSetting.find_or_create
        model_profile = setting.model_profile
        raise "Model Profile not found" unless model_profile
        llm_options = {}
        llm_options[:organization_id] = model_profile.organization_id if model_profile.organization_id
        llm_options[:embedding_model] = setting.embedding_model unless setting.embedding_model.blank?
        default_options = {
          model: model_profile.llm_model,
          temperature: 0.5,
        }
        default_options[:embedding_model] = setting.embedding_model unless setting.embedding_model.blank?
        client = Langchain::LLM::OpenAI.new(
          api_key: model_profile.access_key,
          llm_options: llm_options,
          default_options: default_options,
        )
        raise "OpenAI LLM Create Error" unless client
        client
      end
    end
  end
end
