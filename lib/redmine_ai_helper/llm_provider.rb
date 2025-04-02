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
        Setting.plugin_redmine_ai_helper["llm"]
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

    def generate_client
      raise NotImplementedError, "LLM provider not found"
    end

    def create_chat_param(system_prompt, messages)
      new_messages = messages.dup
        new_messages.unshift(system_prompt)
        {
          messages: new_messages,
        }
    end

    def dig_keyword
      "content"
    end

    private
  end
end
