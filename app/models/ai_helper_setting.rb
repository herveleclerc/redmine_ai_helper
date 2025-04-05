class AiHelperSetting < ApplicationRecord
  include Redmine::SafeAttributes
  belongs_to :model_profile, class_name: "AiHelperModelProfile"
  validates :model_profile, presence: true

  safe_attributes 'model_profile', 'additional_instructions'

  def AiHelperSetting::find_or_create
    setting = AiHelperSetting.order(:id).first
    setting || AiHelperSetting.new
  end
end
