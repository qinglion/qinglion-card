class SessionsController < ApplicationController
  before_action :authenticate_user!, only: [:show, :devices, :destroy_one]
  before_action :check_session_cookie_availability, only: [:new]

  def show
    @session = Current.session
    @user = current_user
  end

  def devices
    @sessions = current_user.sessions.order(created_at: :desc)
  end

  def new
    @user = User.new
  end

  def create
    if user = User.authenticate_by(email: params[:user][:email], password: params[:user][:password])
      # 检查用户是否已激活
      unless user.activated?
        redirect_to sign_in_path(email_hint: params[:user][:email]), 
                    alert: "您的账号尚未激活，请等待管理员审核通过后再登录"
        return
      end
      
      @session = user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }
      redirect_to root_path, notice: "登录成功"
    else
      redirect_to sign_in_path(email_hint: params[:user][:email]), alert: "邮箱或密码错误"
    end
  end


  def destroy
    @session = Current.session
    @session.destroy!
    cookies.delete(:session_token)
    redirect_to(sign_in_path, notice: "该会话已退出登录")
  end

  def destroy_one
    @session = current_user.sessions.find(params[:id])
    @session.destroy!
    redirect_to(devices_session_path, notice: "该会话已退出登录")
  end
end
