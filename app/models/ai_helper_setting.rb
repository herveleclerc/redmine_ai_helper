class AiHelperSetting < ApplicationRecord
  include Redmine::SafeAttributes
  belongs_to :model_profile, class_name: "AiHelperModelProfile"

  safe_attributes 'model_profile_id', 'additional_instructions'

  def AiHelperSetting::find_or_create
    setting = AiHelperSetting.order(:id).first
    setting || AiHelperSetting.create!
  end
end
