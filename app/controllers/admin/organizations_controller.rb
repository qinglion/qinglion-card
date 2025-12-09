class Admin::OrganizationsController < Admin::BaseController
  before_action :set_organization, only: [:show, :edit, :update, :destroy, :members, :approve_member, :reject_member]

  def index
    @organizations = Organization.page(params[:page]).per(10)
  end

  def show
  end

  def new
    @organization = Organization.new
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      redirect_to admin_organization_path(@organization), notice: 'Organization was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @organization.update(organization_params)
      redirect_to admin_organization_path(@organization), notice: 'Organization was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @organization.destroy
    redirect_to admin_organizations_path, notice: 'Organization was successfully deleted.'
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
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name, :description, :admin_user_id, :logo, :background_image)
  end
end
