class Sessions::OmniauthController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def create
    @user = User.from_omniauth(omniauth)

    if @user.persisted?
      session_record = @user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }

      redirect_to root_path, notice: "\u6210\u529f\u4f7f\u7528 #{omniauth.provider.humanize} \u767b\u5f55"
    else
      flash[:alert] = handle_password_errors(@user)
      redirect_to sign_in_path
    end
  end

  def failure
    error_type = params[:message] || request.env['omniauth.error.type']

    error_message = case error_type.to_s
    when 'access_denied'
      "\u6388\u6743\u5df2\u53d6\u6d88\u3002\u5982\u679c\u60a8\u60f3\u767b\u5f55\uff0c\u8bf7\u91cd\u8bd5\u3002"
    when 'invalid_credentials'
      "\u63d0\u4f9b\u7684\u51ed\u636e\u65e0\u6548\u3002\u8bf7\u68c0\u67e5\u60a8\u7684\u4fe1\u606f\u5e76\u91cd\u8bd5\u3002"
    when 'timeout'
      "\u8ba4\u8bc1\u8d85\u65f6\u3002\u8bf7\u91cd\u8bd5\u3002"
    else
      "\u8ba4\u8bc1\u5931\u8d25\uff1a#{error_type&.to_s&.humanize || '\u672a\u77e5\u9519\u8bef'}"
    end

    flash[:alert] = error_message
    redirect_to sign_in_path
  end

  private

  def omniauth
    request.env["omniauth.auth"]
  end
end
