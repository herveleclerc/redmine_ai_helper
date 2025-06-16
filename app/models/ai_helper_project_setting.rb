class AiHelperProjectSetting < ApplicationRecord
  def self.settings(project)
    setting = AiHelperProjectSetting.where(project_id: project.id).first
    if setting.nil?
      setting = AiHelperProjectSetting.new
      setting.project_id = project.id
      setting.save!
    end
    setting
  end
end
