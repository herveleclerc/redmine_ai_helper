require 'openai'
module RedmineAiHelper

  BASE_URL = 'https://api.openai.com/v1'.freeze
  class Llm
    def initialize(params = {})
      params[:access_token] ||= Setting.plugin_redmine_ai_helper['access_token']
      params[:uri_base] ||= Settings.plugin_redmine_ai_helper['uri_base']
      params[:organization_id] ||= Setting.plugin_redmine_ai_helper['organization_id']

      params[:uri_base] = BASE_URL if params[:uri_base].blank?
      @client = OpenAI::Client.new(params)
    end
  end
end
