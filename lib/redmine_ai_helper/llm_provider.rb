module RedmineAiHelper
  class LlmProvider
    LLM_OPENAI = "OpenAI".freeze
    LLM_GEMINI = "Gemini".freeze
    class << self
      def get_llm
        provider = RedmineAiHelper::LlmProvider.new
        case provider.config["llm"]
        when LLM_OPENAI
          provider.generate_openai_client
        when LLM_GEMINI
          raise NotImplementedError, "Gemini LLM is not implemented yet"
        else
          raise NotImplementedError, "LLM provider not found"
        end

      end

      def option_for_select
        llms = [
          LLM_OPENAI,
          LLM_GEMINI
        ]
        llms.map do |llm|
          [llm, llm]
        end
      end
    end

    def config
      Setting.plugin_redmine_ai_helper
    end

    def generate_openai_client
      llm_options = {}
      llm_options[:organization_id] = config["organization_id"] if config["organization_id"].present?
      @client = Langchain::LLM::OpenAI.new(
        api_key: config["access_token"],
        llm_options: llm_options,
        default_options: {
          chat_model: config["model"],
          temperature: 0.5,
        },
      )
    end
  end
end
