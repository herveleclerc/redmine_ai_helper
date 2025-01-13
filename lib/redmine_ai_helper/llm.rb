require 'openai'
module RedmineAiHelper

  class Llm
    attr_accessor :model
    def initialize(params = {})
      params[:access_token] ||= Setting.plugin_redmine_ai_helper['access_token']
      params[:uri_base] ||= Setting.plugin_redmine_ai_helper['uri_base']
      params[:organization_id] ||= Setting.plugin_redmine_ai_helper['organization_id']
      @model ||= Setting.plugin_redmine_ai_helper['model']

      @client = OpenAI::Client.new(params)
    end

    def chat(conversation)
      response = @client.chat(
        parameters: {
          model: @model,
          messages: conversation.messages.map do |message|
            {
              role: message.role,
              content: message.content
            }
          end
        }
      )

      AiHelperMessage.new(role: 'assistant', content: response['choices'][0]['message']['content'], conversation: conversation)
    end
  end
end
