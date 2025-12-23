class RegistrationsController < ApplicationController
  before_action :check_session_cookie_availability, only: [:new]

  def new
    @user = User.new
  end
  
  def pending_approval
    # Show pending approval page
  end

  def create
    @user = User.new(user_params)
    @user.activated = false  # Set to pending activation

    if @user.save
      # Don't create session for pending users
      # Don't send email verification yet
      redirect_to pending_approval_registrations_path, notice: "注册申请已提交，请添加微信加入《人脉高手社区》"
    else
      flash.now[:alert] = handle_password_errors(@user)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def send_email_verification
    UserMailer.with(user: @user).email_verification.deliver_later
  end
end
