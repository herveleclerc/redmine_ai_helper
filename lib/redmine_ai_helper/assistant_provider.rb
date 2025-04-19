module RedmineAiHelper
  class AssistantProvider
    class << self
      def get_assistant(llm_type:, llm:, instructions:, tools: [])
        case llm_type
        when LlmProvider::LLM_GEMINI
          return RedmineAiHelper::Assistants::GeminiAssistant.new(
                   llm: llm,
                   instructions: instructions,
                   tools: tools,
                 )
        else
          return RedmineAiHelper::Assistant.new(
                   llm: llm,
                   instructions: instructions,
                   tools: tools,
                 )
        end
      end
    end
  end
end
