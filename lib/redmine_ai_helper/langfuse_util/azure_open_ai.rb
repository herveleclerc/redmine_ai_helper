module RedmineAiHelper
  module LangfuseUtil
    # Wrapper for OpenAI.
    class AzureOpenAi < Langchain::LLM::Azure
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
          generation = span.create_generation(name: "chat", messages: params[:messages], model: parameters[:model], temperature: parameters[:temperature], max_tokens: max_tokens)
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
