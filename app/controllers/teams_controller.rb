class TeamsController < ApplicationController

  def index
    @full_render = true  # Hide navbar for teams view
    @current_user_profile = current_user&.profile
    
    # Get organization based on profile_id parameter
    if params[:profile_id].present?
      @profile = Profile.find_by(id: params[:profile_id])
      @organization = @profile&.organization
    else
      # Fallback to current user's profile
      @profile = @current_user_profile
      @organization = @profile&.organization
    end

    # Auto-assign to default organization if user has no organization
    if @current_user_profile && !@current_user_profile.organization
      default_org = Organization.first
      if default_org
        @current_user_profile.update(organization: default_org, status: 'approved')
        @organization = default_org
      end
    end

    if @organization
      @members = @organization.approved_profiles
                              .includes(:user)
                              .order('profiles.department ASC, profiles.full_name ASC')
      @departments = @members.group_by(&:department)
      
      # Check if current user is admin of this organization
      @is_admin = current_user && @organization.is_admin?(current_user)
      @is_own_profile = @profile&.id == @current_user_profile&.id
    end
  end

  private
  # Write your private methods here
end
