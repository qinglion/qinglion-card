class Admin::OrganizationsController < Admin::BaseController
  before_action :set_organization

  def edit
  end

  def update
    if @organization.update(organization_params)
      redirect_to edit_admin_organization_path, notice: '组织设置已成功更新。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def members
    @pending_profiles = @organization.pending_profiles.page(params[:pending_page]).per(10)
    @approved_profiles = @organization.approved_profiles.page(params[:approved_page]).per(10)
    @rejected_profiles = @organization.rejected_profiles.page(params[:rejected_page]).per(10)
  end

  def approve_member
    profile = @organization.profiles.find(params[:profile_id])
    if profile.approve!
      redirect_to members_admin_organization_path(@organization), notice: '成员已成功批准。'
    else
      redirect_to members_admin_organization_path(@organization), alert: '批准成员失败。'
    end
  end

  def reject_member
    profile = @organization.profiles.find(params[:profile_id])
    if profile.reject!
      redirect_to members_admin_organization_path(@organization), notice: '成员已成功拒绝。'
    else
      redirect_to members_admin_organization_path(@organization), alert: '拒绝成员失败。'
    end
  end

  def reactivate_member
    profile = @organization.profiles.find(params[:profile_id])
    if profile.update(status: 'pending')
      redirect_to members_admin_organization_path(@organization), notice: '成员已成功移至待审核列表。'
    else
      redirect_to members_admin_organization_path(@organization), alert: '重新审核成员失败。'
    end
  end

  def destroy_member
    profile = @organization.profiles.find(params[:profile_id])
    if profile.destroy
      redirect_to members_admin_organization_path(@organization), notice: '成员已永久删除。'
    else
      redirect_to members_admin_organization_path(@organization), alert: '删除成员失败。'
    end
  end
  
  def add_user
    email = params[:email]&.strip&.downcase
    
    if email.blank?
      redirect_to members_admin_organization_path(@organization), alert: '请输入用户邮箱。'
      return
    end
    
    user = User.find_by(email: email)
    
    if user.nil?
      redirect_to members_admin_organization_path(@organization), alert: "未找到邮箱为 #{email} 的用户。"
      return
    end
    
    profile = user.profile
    
    if profile.nil?
      redirect_to members_admin_organization_path(@organization), alert: '该用户没有个人资料。'
      return
    end
    
    # Check if profile already belongs to this organization
    if profile.organization_id == @organization.id && profile.status != 'rejected'
      redirect_to members_admin_organization_path(@organization), alert: '该用户已在组织中。'
      return
    end
    
    # Add user to organization as approved and activate the user
    if profile.update(organization: @organization, status: 'approved') && user.update(activated: true)
      redirect_to members_admin_organization_path(@organization), notice: "用户 #{email} 已成功添加到已批准成员。"
    else
      redirect_to members_admin_organization_path(@organization), alert: '添加用户失败。'
    end
  end
  
  def resend_approval_email
    profile = @organization.profiles.find(params[:profile_id])
    
    unless profile.approved?
      redirect_to members_admin_organization_path(@organization), alert: '只能对已批准的成员重新发送邮件。'
      return
    end
    
    user = profile.user
    
    if user.nil?
      redirect_to members_admin_organization_path(@organization), alert: '该成员没有关联的用户账户。'
      return
    end
    
    begin
      token = user.generate_registration_token
      UserMailer.with(
        user: user,
        token: token,
        organization_name: @organization.name
      ).approval_notification.deliver_now
      
      redirect_to members_admin_organization_path(@organization), notice: "已成功重新发送邮件至 #{user.email}。"
    rescue => e
      Rails.logger.error "Failed to resend approval email: #{e.message}"
      redirect_to members_admin_organization_path(@organization), alert: "邮件发送失败：#{e.message}"
    end
  end

  private

  def set_organization
    @organization = Organization.first_or_create!(
      name: '默认组织',
      description: '系统默认组织'
    )
  end

  def organization_params
    params.require(:organization).permit(
      :name, :description, :logo, :background_image,
      :service_advantage_1_title, :service_advantage_1_description,
      :service_advantage_2_title, :service_advantage_2_description,
      :service_advantage_3_title, :service_advantage_3_description,
      :service_process_1_title, :service_process_1_description,
      :service_process_2_title, :service_process_2_description,
      :service_process_3_title, :service_process_3_description,
      :service_process_4_title, :service_process_4_description,
      :cta_title, :cta_description
    )
  end
end
