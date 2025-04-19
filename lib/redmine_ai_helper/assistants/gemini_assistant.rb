module RedmineAiHelper
  module Assistants
    class GeminiAssistant < RedmineAiHelper::Assistant
      def add_message(role: "user", content: nil, image_url: nil, tool_calls: [], tool_call_id: nil)
        new_role = role
        case role
        when "assistant"
          new_role = "model"
        end
        super(
          role: new_role,
          content: content,
          image_url: image_url,
          tool_calls: tool_calls,
          tool_call_id: tool_call_id,
        )
      end
    end
  end
end
