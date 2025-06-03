module RedmineAiHelper
  module LangfuseUtil
    # Wrapper for Anthropic.
    class Anthropic < Langchain::LLM::Anthropic
      attr_accessor :langfuse

      # Override the chat method to handle tool calls.
      # @param [Hash] params Parameters for the chat request.
      # @param [Proc] block Block to handle the response.
      # @return The response from the chat.
      def chat(params = {}, &block)
        generation = nil
        if @langfuse&.current_span
          parameters = chat_parameters.to_params(params)
          span = @langfuse.current_span
          max_tokens = parameters[:max_tokens] || @defaults[:max_tokens]
          new_messages = []
          new_messages << { role: "system", content: params[:system] } if params[:system]
          new_messages = new_messages + params[:messages]
          generation = span.create_generation(name: "chat", messages: new_messages, model: parameters[:model], temperature: parameters[:temperature], max_tokens: max_tokens)
        end
        response = super(params, &block)
        if generation
          usage = {
            prompt_tokens: response.prompt_tokens,
            completion_tokens: response.completion_tokens,
            total_tokens: response.total_tokens,
          }
          generation.finish(output: response.chat_completion, usage: usage)
        end
        response
      end
    end
  end
end
