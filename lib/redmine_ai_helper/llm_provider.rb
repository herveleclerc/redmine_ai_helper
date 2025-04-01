module RedmineAiHelper
  class LlmProvider
    LLM_OPENAI = "OpenAI".freeze
    LLM_GEMINI = "Gemini".freeze
    LLM_ANTHROPIC = "Anthropic".freeze
    class << self
      def get_llm
        provider = RedmineAiHelper::LlmProvider.new
        case provider.config["llm"]
        when LLM_OPENAI
          return provider.generate_openai_client
        when LLM_GEMINI
          raise NotImplementedError, "Gemini LLM is not implemented yet"
        when LLM_ANTHROPIC
          return provider.generate_anthropic_client
        else
          raise NotImplementedError, "LLM provider not found"
        end
      end

      def type
        provider = RedmineAiHelper::LlmProvider.new
        provider.config["llm"]
      end

      def option_for_select
        llms = [
          LLM_OPENAI,
          LLM_GEMINI,
          LLM_ANTHROPIC,
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

    def generate_anthropic_client
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
