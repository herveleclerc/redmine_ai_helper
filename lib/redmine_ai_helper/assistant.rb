# frozen_string_literal: true
# TODO: Move this to assistants directory.
require "langchain"

module RedmineAiHelper
  # Base class for all assistants.
  class Assistant < Langchain::Assistant
    attr_accessor :llm_provider
    @llm_provider = nil
  end
end
