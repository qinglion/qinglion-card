class TeamsController < ApplicationController
  before_action :authenticate_user!

  def index
    @full_render = true  # Hide navbar for teams view
    @profile = current_user.profile
    @organization = @profile&.organization

    # Auto-assign to default organization if user has no organization
    if @profile && !@organization
      default_org = Organization.first
      if default_org
        @profile.update(organization: default_org, status: 'approved')
        @organization = default_org
      end
    end

    if @organization
      @members = @organization.approved_profiles
                              .includes(:user)
                              .order('profiles.department ASC, profiles.full_name ASC')
      @departments = @members.group_by(&:department)
    end
  end

  private
  # Write your private methods here
end
