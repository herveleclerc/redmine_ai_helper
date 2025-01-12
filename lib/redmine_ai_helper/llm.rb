require 'openai'
module RedmineAiHelper
  class Llm
    def initialize(params = {})
      @client = OpenAI::Client.new(access_token: "access_token_goes_here")
    end
  end
end
