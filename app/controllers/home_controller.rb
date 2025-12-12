class HomeController < ApplicationController
  include HomeDemoConcern

  def index
    # 获取主组织信息（假设系统中只有一个组织，或者获取第一个）
    @organization = Organization.first
    
    # 如果没有组织，创建默认组织
    unless @organization
      @organization = Organization.create!(
        name: Rails.application.config.x.appname || 'Professional Digital Cards',
        description: '专业数字名片平台，让每一位专业人士拥有自己的智能数字名片'
      )
    end
    
    # 获取组织的成员（已审核通过的 profiles）
    @team_members = @organization.approved_profiles.includes(:user).limit(6)
  end
end
