class Admin::OrganizationsController < Admin::BaseController
  before_action :set_organization

  def edit
  end

  def update
    if @organization.update(organization_params)
      redirect_to edit_admin_organization_path, notice: 'Organization settings updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def members
    @pending_profiles = @organization.pending_profiles.page(params[:pending_page]).per(10)
    @approved_profiles = @organization.approved_profiles.page(params[:approved_page]).per(10)
  end

  def approve_member
    profile = @organization.profiles.find(params[:profile_id])
    if profile.approve!
      redirect_to members_admin_organization_path(@organization), notice: 'Member approved successfully.'
    else
      redirect_to members_admin_organization_path(@organization), alert: 'Failed to approve member.'
    end
  end

  def reject_member
    profile = @organization.profiles.find(params[:profile_id])
    if profile.reject!
      redirect_to members_admin_organization_path(@organization), notice: 'Member rejected successfully.'
    else
      redirect_to members_admin_organization_path(@organization), alert: 'Failed to reject member.'
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
    params.require(:organization).permit(:name, :description, :logo, :background_image)
  end
end
