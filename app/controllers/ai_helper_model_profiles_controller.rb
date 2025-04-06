class AiHelperModelProfilesController < ApplicationController
  layout 'admin'
  before_action :require_admin
  before_action :find_model_profile, only: [:show, :edit, :update, :destroy]
  self.main_menu = false

  def show
    render partial: 'ai_helper_model_profiles/show'
  end

  def new
    @title = l('ai_helper.model_profiles.create_profile_title')
    @model_profile = AiHelperModelProfile.new
  end

  def create
    @model_profile = AiHelperModelProfile.new
    @model_profile.safe_attributes = params[:ai_helper_model_profile]
    if @model_profile.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to ai_helper_setting_path
    else
      render action: :new
    end
  end

  def edit
  end

  def update

  end

  def destroy
  end

  private
  def find_model_profile
    id = params[:id]
    return if params[:id].blank?
    @model_profile = AiHelperModelProfile.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
