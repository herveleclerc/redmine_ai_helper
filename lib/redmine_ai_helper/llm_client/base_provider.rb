module RedmineAiHelper
  module LlmClient
    class BaseProvider

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

      def chunk_converter(chunk)
        chunk.dig("delta", "content")
      end
    end
  end
end
