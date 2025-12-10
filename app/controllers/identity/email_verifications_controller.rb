class Identity::EmailVerificationsController < ApplicationController
  before_action :authenticate_user!, only: :create

  before_action :set_user, only: :show

  def show
    @user.update! verified: true
    redirect_to profile_path, notice: "\u611f\u8c22\u60a8\u9a8c\u8bc1\u90ae\u7bb1\u5730\u5740"
  end

  def create
    if current_user.email_was_generated?
      redirect_to profile_path, alert: "\u60a8\u7684\u90ae\u7bb1\u662f\u7cfb\u7edf\u751f\u6210\u7684\uff0c\u65e0\u6cd5\u9a8c\u8bc1\u3002\u8bf7\u66f4\u65b0\u4e3a\u6709\u6548\u7684\u90ae\u7bb1\u5730\u5740\u3002"; return
    end
    send_email_verification
    redirect_to profile_path, notice: "\u6211\u4eec\u5df2\u5411\u60a8\u7684\u90ae\u7bb1\u53d1\u9001\u9a8c\u8bc1\u90ae\u4ef6"
  end

  private

  def set_user
    @user = User.find_by_token_for!(:email_verification, params[:sid])
  rescue StandardError
    redirect_to edit_identity_email_path, alert: "\u8be5\u90ae\u7bb1\u9a8c\u8bc1\u94fe\u63a5\u65e0\u6548"
  end

  def send_email_verification
    UserMailer.with(user: Current.user).email_verification.deliver_later
  end
end
