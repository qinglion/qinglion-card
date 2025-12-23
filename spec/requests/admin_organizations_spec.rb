require 'rails_helper'

RSpec.describe "Admin::Organizations", type: :request do
  before { admin_sign_in_as(create(:administrator)) }

  describe "GET /admin/organization/edit" do
    it "returns http success" do
      get edit_admin_organization_path
      expect(response).to be_success_with_view_check('edit')
    end
  end

  describe "GET /admin/organization/members" do
    it "returns http success" do
      get members_admin_organization_path
      expect(response).to be_success_with_view_check('members')
    end
  end

  describe "PATCH /admin/organization" do
    it "updates organization settings" do
      patch admin_organization_path, params: {
        organization: {
          name: '新组织名称',
          description: '更新后的描述'
        }
      }
      expect(response).to redirect_to(edit_admin_organization_path)
      expect(Organization.first.name).to eq('新组织名称')
    end
  end

  describe "POST /admin/organization/members/:profile_id/reactivate" do
    it "moves rejected member back to pending status" do
      organization = Organization.first_or_create!(name: '人脉主页')
      profile = create(:profile, organization: organization, status: 'rejected')
      
      post reactivate_member_admin_organization_path(profile_id: profile.id)
      
      expect(response).to have_http_status(:redirect)
      expect(profile.reload.status).to eq('pending')
    end
  end

  describe "DELETE /admin/organization/members/:profile_id/destroy" do
    it "permanently deletes a member" do
      organization = Organization.first_or_create!(name: '人脉主页')
      profile = create(:profile, organization: organization, status: 'rejected')
      
      expect {
        delete destroy_member_admin_organization_path(profile_id: profile.id)
      }.to change(Profile, :count).by(-1)
      
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "POST /admin/organization/members/:profile_id/resend_email" do
    let(:organization) { Organization.first_or_create!(name: '人脉主页') }
    
    it "resends approval email to approved member" do
      user = create(:user)
      profile = user.profile
      profile.update(organization: organization, status: 'approved')
      
      expect {
        post resend_email_member_admin_organization_path(profile_id: profile.id)
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      
      expect(response).to have_http_status(:redirect)
      expect(flash[:notice]).to include('已成功重新发送邮件')
      
      # Verify email content
      email = ActionMailer::Base.deliveries.last
      expect(email.to).to include(user.email)
      expect(email.subject).to include('您的申请已通过审核')
    end
    
    it "does not resend email to non-approved member" do
      user = create(:user)
      profile = user.profile
      profile.update(organization: organization, status: 'pending')
      
      post resend_email_member_admin_organization_path(profile_id: profile.id)
      
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to include('只能对已批准的成员重新发送邮件')
    end
    
    it "handles error when profile has no user" do
      profile = create(:profile, organization: organization, status: 'approved')
      profile.update_column(:user_id, nil)
      
      post resend_email_member_admin_organization_path(profile_id: profile.id)
      
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to include('该成员没有关联的用户账户')
    end
  end

  describe "POST /admin/organization/add_user" do
    let(:organization) { Organization.first_or_create!(name: '人脉主页') }
    
    it "adds a user to approved members by email" do
      user = create(:user)
      
      post add_user_admin_organization_path, params: { email: user.email }
      
      expect(response).to have_http_status(:redirect)
      expect(user.profile.reload.organization).to eq(organization)
      expect(user.profile.reload.status).to eq('approved')
    end
    
    it "does not add user with blank email" do
      post add_user_admin_organization_path, params: { email: '' }
      
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to include('请输入用户邮箱')
    end
    
    it "does not add non-existent user" do
      post add_user_admin_organization_path, params: { email: 'nonexistent@example.com' }
      
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to include('未找到邮箱')
    end
    
    it "does not add user without profile" do
      user = create(:user)
      user.profile.destroy
      
      post add_user_admin_organization_path, params: { email: user.email }
      
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to include('该用户没有个人资料')
    end
    
    it "does not add user already in organization" do
      user = create(:user)
      user.profile.update(organization: organization, status: 'approved')
      
      post add_user_admin_organization_path, params: { email: user.email }
      
      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to include('该用户已在组织中')
    end
  end
end
