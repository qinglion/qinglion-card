class UserMailer < ApplicationMailer
  def password_reset
    @user = params[:user]
    @signed_id = @user.generate_token_for(:password_reset)

    mail to: @user.email, subject: "[#{Rails.application.config.x.appname}] Reset your password"
  end

  def email_verification
    @user = params[:user]
    @signed_id = @user.generate_token_for(:email_verification)

    mail to: @user.email, subject: "[#{Rails.application.config.x.appname}] Verify your email"
  end

  def invitation_instructions
    @user = params[:user]
    @signed_id = @user.generate_token_for(:password_reset)

    mail to: @user.email, subject: "[#{Rails.application.config.x.appname}] Invitation instructions"
  end
  
  def approval_notification
    @user = params[:user]
    @token = params[:token]
    @organization_name = params[:organization_name]
    
    mail(
      to: @user.email, 
      subject: "[#{@organization_name}] 您的申请已通过审核",
      from: "#{@organization_name} <notifications@#{ENV.fetch('EMAIL_SMTP_DOMAIN', 'example.com')}>"
    )
  end
end
