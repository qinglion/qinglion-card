class Identity::PasswordResetsController < ApplicationController
  before_action :set_user, only: %i[ edit update ]

  def new
    @user = User.new
  end

  def edit
  end

  def create
    if @user = User.find_by(email: params[:user][:email], verified: true)
      send_password_reset_email
      redirect_to sign_in_path, notice: "\u8bf7\u67e5\u770b\u60a8\u7684\u90ae\u7bb1\u83b7\u53d6\u91cd\u7f6e\u5bc6\u7801\u6307\u5f15"
    else
      redirect_to new_identity_password_reset_path, alert: "\u5728\u9a8c\u8bc1\u60a8\u7684\u90ae\u7bb1\u4e4b\u524d\uff0c\u65e0\u6cd5\u91cd\u7f6e\u5bc6\u7801"
    end
  end

  def update
    if @user.update(user_params)
      redirect_to sign_in_path, notice: "\u5bc6\u7801\u91cd\u7f6e\u6210\u529f\uff0c\u8bf7\u767b\u5f55"
    else
      flash.now[:alert] = handle_password_errors(@user)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find_by_token_for!(:password_reset, params[:sid])
  rescue StandardError
    redirect_to new_identity_password_reset_path, alert: "\u8be5\u5bc6\u7801\u91cd\u7f6e\u94fe\u63a5\u65e0\u6548"
  end

  def user_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def send_password_reset_email
    UserMailer.with(user: @user).password_reset.deliver_later
  end
end
