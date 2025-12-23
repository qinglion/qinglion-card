class HomeController < ApplicationController
  include HomeDemoConcern

  def index
    # 获取主组织信息（假设系统中只有一个组织，或者获取第一个）
    @organization = Organization.first
    
    # 如果没有组织，创建默认的人脉主页
    unless @organization
      @organization = Organization.create!(
        name: Rails.application.config.x.appname || '人脉主页',
        description: '基于黄金圈理念，为每位伙伴构建可在微信生态传播的个人品牌页面'
      )
    end
    
    # 获取组织的成员（已审核通过的 profiles）
    @team_members = @organization.approved_profiles.includes(:user).limit(6)
  end
end
