# A model for storing AI helper setting
# There is only one record of this model in the system
class AiHelperSetting < ApplicationRecord
  include Redmine::SafeAttributes
  belongs_to :model_profile, class_name: "AiHelperModelProfile"

  safe_attributes "model_profile_id", "additional_instructions"

  # Returns the one and only record of AiHelperSetting or creates a new one if it doesn't exist
  #
  def AiHelperSetting::find_or_create
    setting = AiHelperSetting.order(:id).first
    setting || AiHelperSetting.create!
  end
end
