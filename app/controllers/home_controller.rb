class HomeController < ApplicationController
  include HomeDemoConcern

  def index
    # 获取组织的已审核成员（兼容现有数据库）
    organization = Organization.first
    @team_members = organization ? organization.approved_profiles.includes(:user).limit(6) : []
  end
end
