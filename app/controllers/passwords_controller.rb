class PasswordsController < ApplicationController
  before_action :authenticate_user!
  def edit
    @user = current_user
  end

  def update
    if current_user.update(user_params)
      redirect_to root_path, notice: "\u60a8\u7684\u5bc6\u7801\u5df2\u66f4\u6539"
    else
      flash.now[:alert] = handle_password_errors(current_user)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:password, :password_confirmation, :password_challenge).with_defaults(password_challenge: "")
  end
end
