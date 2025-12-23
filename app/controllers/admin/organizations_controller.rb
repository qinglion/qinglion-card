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
    # Base scopes
    pending_scope = @organization.pending_profiles
    approved_scope = @organization.approved_profiles
    rejected_scope = @organization.rejected_profiles
    
    # Filter by category if specified
    if params[:category].present?
      @selected_category = params[:category]
      pending_scope = pending_scope.where(member_category: @selected_category)
      approved_scope = approved_scope.where(member_category: @selected_category)
      rejected_scope = rejected_scope.where(member_category: @selected_category)
    end
    
    # Filter by status if specified
    if params[:status] == 'uncategorized'
      pending_scope = pending_scope.where(member_category: nil)
      approved_scope = approved_scope.where(member_category: nil)
      rejected_scope = rejected_scope.where(member_category: nil)
    end
    
    @pending_profiles = pending_scope.page(params[:pending_page]).per(10)
    @approved_profiles = approved_scope.page(params[:approved_page]).per(10)
    @rejected_profiles = rejected_scope.page(params[:rejected_page]).per(10)
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
      name: '人脉主页',
      description: '基于黄金圈理念，为每位伙伴构建可在微信生态传播的个人品牌页面'
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
