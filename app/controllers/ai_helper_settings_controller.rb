# Controller for managing AI Helper settings
# This controller allows administrators to update the settings for the AI Helper plugin.
# It includes methods for displaying the settings form and saving the updated settings.
class AiHelperSettingsController < ApplicationController
  layout "admin"
  before_action :require_admin, :find_setting
  self.main_menu = false

  # Display the setting form
  def index
  end

  # Update the setting
  def update
    @setting.safe_attributes = params[:ai_helper_setting]
    if @setting.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: :index
    else
      render action: :index
    end
  end

  private

  def find_setting
    @setting = AiHelperSetting.find_or_create
    @model_profiles = AiHelperModelProfile.order(:name)
  end
end
