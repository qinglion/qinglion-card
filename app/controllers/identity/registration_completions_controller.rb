class Identity::RegistrationCompletionsController < ApplicationController
  skip_before_action :set_current_request_details
  before_action :set_user, only: [:edit, :update]

  def edit
  end

  def update
    if @user.update(user_params)
      @user.clear_registration_token!
      redirect_to sign_in_path, notice: "密码设置成功！请使用邮箱和密码登录"
    else
      flash.now[:alert] = "密码设置失败，请检查输入"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    token = params[:token]
    @user = User.find_by(registration_token: token)
    
    unless @user && @user.valid_registration_token?(token)
      redirect_to root_path, alert: "注册链接无效或已过期，请联系管理员"
    end
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
