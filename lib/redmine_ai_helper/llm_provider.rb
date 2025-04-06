require_relative "llm_client/open_ai_provider"
require_relative "llm_client/anthropic_provider"
module RedmineAiHelper
  class LlmProvider
    LLM_OPENAI = "OpenAI".freeze
    LLM_GEMINI = "Gemini".freeze
    LLM_ANTHROPIC = "Anthropic".freeze
    class << self
      def get_llm_provider
        case type
        when LLM_OPENAI
          return RedmineAiHelper::LlmClient::OpenAiProvider.new
        when LLM_GEMINI
          raise NotImplementedError, "Gemini LLM is not implemented yet"
        when LLM_ANTHROPIC
          return RedmineAiHelper::LlmClient::AnthropicProvider.new
        else
          raise NotImplementedError, "LLM provider not found"
        end
      end

      def type
        setting = AiHelperSetting.find_or_create
        setting.model_profile.llm_type
      end

      def option_for_select
        [
          ["OpenAI", LLM_OPENAI],
          ["Gemini(Experimental)", LLM_GEMINI],
          ["Anthropic(Experimental)", LLM_ANTHROPIC],
        ]
      end
    end
  end
end
