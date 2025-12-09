class Admin::ProfilesController < Admin::BaseController
  before_action :set_profile, only: [:show, :edit, :update, :destroy]

  def index
    @profiles = Profile.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @profile = Profile.new
  end

  def create
    @profile = Profile.new(profile_params)

    if @profile.save
      redirect_to admin_profile_path(@profile), notice: 'Profile was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      # If coming from onboarding, redirect back to onboarding
      if params[:from_onboarding]
        redirect_to onboardings_path, notice: '保存成功！继续完善信息或预览名片'
      else
        redirect_to admin_profile_path(@profile), notice: 'Profile was successfully updated.'
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @profile.destroy
    redirect_to admin_profiles_path, notice: 'Profile was successfully deleted.'
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
  end

  def profile_params
    params.require(:profile).permit(:full_name, :title, :company, :phone, :email, :location, :bio, :specializations, :avatar_url, :avatar, :background_image, :department, :stats, :slug, :user_id)
  end
end
