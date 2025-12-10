require 'rails_helper'

RSpec.describe "Invitations", type: :request do
  let!(:organization) { FactoryBot.create(:organization, name: "测试医院") }

  describe "GET /invitation/new" do
    it "renders invitation form with valid token" do
      get new_invitation_path, params: { token: organization.invite_token }
      expect(response).to have_http_status(:success)
    end
    
    it "redirects when token is missing" do
      get new_invitation_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/邀请链接无效/)
    end
    
    it "redirects when token is invalid" do
      get new_invitation_path, params: { token: 'invalid_token' }
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/邀请链接无效/)
    end
  end

  describe "POST /invitation" do
    let(:valid_params) do
      {
        token: organization.invite_token,
        user: {
          email: "newmember@example.com",
          profile_attributes: {
            full_name: "张三丰",
            title: "主任医师",
            department: "内科",
            bio: "从事内科临床工作20年"
          }
        }
      }
    end

    it "creates a new user with pending activation" do
      expect {
        post invitation_path, params: valid_params
      }.to change(User, :count).by(1)
        .and change(Profile, :count).by(1)

      user = User.last
      expect(user.activated).to eq(false)
      expect(user.verified).to eq(false)
      expect(user.name).to eq("newmember") # auto-generated from email
      expect(user.profile.status).to eq("pending")
      expect(user.profile.organization_id).to eq(organization.id)
    end

    it "prevents unactivated user from logging in without password setup" do
      post invitation_path, params: valid_params
      user = User.last

      # User cannot login without setting password first
      post sign_in_path, params: {
        user: {
          email: user.email,
          password: "anypassword"
        }
      }

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include(sign_in_path)
      follow_redirect!
      expect(response.body).to match(/邮箱或密码错误|尚未激活/)
    end

    it "generates registration token after profile approval" do
      post invitation_path, params: valid_params
      user = User.last
      profile = user.profile

      # 管理员审核通过
      profile.approve!
      user.reload

      expect(user.activated).to eq(true)
      expect(profile.status).to eq("approved")
      expect(user.registration_token).to be_present
      expect(user.registration_token_expires_at).to be_present
    end
    
    it "allows user to set password and login with registration token" do
      post invitation_path, params: valid_params
      user = User.last
      profile = user.profile
      
      # Approve and get token
      profile.approve!
      user.reload
      token = user.registration_token

      # User sets password via token link
      patch identity_registration_completion_path(token: token), params: {
        user: {
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }
      }
      
      expect(response).to redirect_to(sign_in_path)
      user.reload
      expect(user.registration_token).to be_nil

      # Now can login with new password
      post sign_in_path, params: {
        user: {
          email: user.email,
          password: "newpassword123"
        }
      }

      expect(response).to redirect_to(root_path)
    end
  end
end
