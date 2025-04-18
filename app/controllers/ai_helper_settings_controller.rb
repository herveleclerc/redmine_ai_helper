class AiHelperSettingsController < ApplicationController
  layout "admin"
  before_action :require_admin, :find_setting
  self.main_menu = false

  def index
  end

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
