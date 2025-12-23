require 'rails_helper'

RSpec.describe 'Admin::MemberCategories', type: :request do
  include AdminAuthenticationHelpers
  
  let!(:admin) { create(:administrator, role: 'admin') }
  let!(:organization) { Organization.first_or_create!(name: '测试组织', description: '测试描述') }
  
  before do
    admin_sign_in_as(admin)
  end
  
  describe 'GET /admin/member_categories' do
    it '显示类别管理页面' do
      get admin_member_categories_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include('类别管理')
      expect(response.body).to include('总成员数')
    end
    
    it '显示所有预定义的类别' do
      get admin_member_categories_path
      Profile::MEMBER_CATEGORIES.each do |category|
        expect(response.body).to include(category)
      end
    end
    
    context '当有成员数据时' do
      let!(:user1) { create(:user, email: 'user1@example.com') }
      let!(:profile1) { create(:profile, user: user1, member_category: '终身卡', organization: organization) }
      let!(:user2) { create(:user, email: 'user2@example.com') }
      let!(:profile2) { create(:profile, user: user2, member_category: '年度会员', organization: organization) }
      let!(:user3) { create(:user, email: 'user3@example.com') }
      let!(:profile3) { create(:profile, user: user3, member_category: nil, organization: organization) }
      
      it '显示正确的统计数据' do
        get admin_member_categories_path
        expect(response.body).to include('3') # 总成员数
      end
    end
  end
end
