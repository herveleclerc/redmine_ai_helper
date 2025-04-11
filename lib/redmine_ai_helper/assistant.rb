require "langchain"

module RedmineAiHelper
  class Assistant < Langchain::Assistant
    attr_accessor :llm_provider
    @llm_provider = nil
  end
end
