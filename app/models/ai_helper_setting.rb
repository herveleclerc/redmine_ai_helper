class AiHelperSetting < ApplicationRecord
  include Redmine::SafeAttributes
  belongs_to :model_profile, class_name: "AiHelperModelProfile"
  validates :vector_search_uri, :presence => true, if: :vector_search_enabled?
  validates :vector_search_uri, :format => { with: URI::regexp(%w[http https]), message: l("ai_helper.model_profiles.messages.must_be_valid_url") }, if: :vector_search_enabled?

  safe_attributes "model_profile_id", "additional_instructions", "version", "vector_search_enabled", "vector_search_uri", "vector_search_api_key"

  def AiHelperSetting::find_or_create
    setting = AiHelperSetting.order(:id).first
    setting || AiHelperSetting.create!
  end
end
