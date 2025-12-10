class InvitationsController < ApplicationController
  skip_before_action :set_current_request_details
  before_action :load_organization_from_token

  def new
    unless @organization
      redirect_to root_path, alert: "邀请链接无效或已过期"
      return
    end
    
    @user = User.new
    @user.build_profile
  end

  def create
    unless @organization
      redirect_to root_path, alert: "邀请链接无效或已过期"
      return
    end
    
    @user = User.new(user_params)
    @user.verified = false
    @user.activated = false
    @user.password = SecureRandom.hex(16)
    
    # Set organization and status for nested profile
    if @user.profile
      @user.profile.organization_id = @organization.id
      @user.profile.status = 'pending'
      @user.profile.email = @user.email
    end
    
    if @user.save
      redirect_to root_path, notice: "申请已提交成功！请等待管理员审核。审核通过后，您将收到邮件通知并可设置密码完成注册。"
    else
      flash.now[:alert] = "提交失败，请检查表单信息"
      render :new, status: :unprocessable_entity
    end
  end

  private
  
  def load_organization_from_token
    token = params[:token]
    @organization = Organization.find_by(invite_token: token) if token.present?
  end

  def user_params
    params.require(:user).permit(
      :email,
      profile_attributes: [:full_name, :title, :department, :bio, :avatar]
    )
  end
end
