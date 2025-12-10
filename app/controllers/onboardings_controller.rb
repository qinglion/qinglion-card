class OnboardingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile

  def index
    # Redirect to dashboard if onboarding is already completed
    if @profile.onboarding_completed
      redirect_to dashboards_path, notice: '您的名片已经设置完成！'
      return
    end
  end

  def skip
    @profile.update(
      onboarding_completed: true,
      onboarding_step: 'skipped'
    )
    redirect_to dashboards_path, notice: '已跳过名片设置，您可以稍后在设置中完善信息。'
  end

  private

  def set_profile
    @profile = current_user.profile || current_user.create_profile(
      full_name: current_user.name || current_user.email.split('@').first.titleize,
      title: 'Professional',
      email: current_user.email
    )
  end
end
