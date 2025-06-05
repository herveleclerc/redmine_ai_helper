# frozen_string_literal: true

require_relative "base_provider"

module RedmineAiHelper
  module LlmClient
    # OpenAiProvider is a specialized provider for handling OpenAI-related queries.
    class AzureOpenAiProvider < RedmineAiHelper::LlmClient::BaseProvider
      # Generate a client for OpenAI LLM
      # @return [Langchain::LLM::OpenAI] the OpenAI client
      def generate_client
        setting = AiHelperSetting.find_or_create
        model_profile = setting.model_profile
        raise "Model Profile not found" unless model_profile
        llm_options = {
          api_type: :azure,
          chat_deployment_url: model_profile.base_uri,
          embedding_deployment_url: setting.embedding_url,
          api_version: "2024-12-01-preview",
        }
        llm_options[:organization_id] = model_profile.organization_id if model_profile.organization_id
        llm_options[:embedding_model] = setting.embedding_model unless setting.embedding_model.blank?
        llm_options[:organization_id] = model_profile.organization_id if model_profile.organization_id
        llm_options[:max_tokens] = setting.max_tokens if setting.max_tokens
        default_options = {
          model: model_profile.llm_model,
          chat_model: model_profile.llm_model,
          temperature: model_profile.temperature,
          embedding_deployment_url: setting.embedding_url,
        }
        default_options[:embedding_model] = setting.embedding_model unless setting.embedding_model.blank?
        default_options[:max_tokens] = setting.max_tokens if setting.max_tokens
        client = RedmineAiHelper::LangfuseUtil::AzureOpenAi.new(
          api_key: model_profile.access_key,
          llm_options: llm_options,
          default_options: default_options,
          chat_deployment_url: model_profile.base_uri,
          embedding_deployment_url: setting.embedding_url,
        )
        raise "OpenAI LLM Create Error" unless client
        client
      end
    end
  end
end
