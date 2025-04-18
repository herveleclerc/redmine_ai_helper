require "langchain"

module RedmineAiHelper
  # Wrapper class for Langchain::Assistant
  class Assistant < Langchain::Assistant
    attr_accessor :llm_provider
    @llm_provider = nil
  end
end
