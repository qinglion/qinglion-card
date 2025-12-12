require 'rails_helper'

RSpec.describe "ShareCard", type: :request do
  let(:user) { User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123') }
  let(:profile) do
    user.profile || user.create_profile(
      full_name: 'Test User',
      title: 'Software Engineer',
      email: user.email,
      slug: 'test',
      bio: 'Test bio',
      phone: '1234567890',
      location: 'Test City',
      onboarding_completed: true
    )
  end

  before do
    # Create profile first
    profile
    # Simulate authentication
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticate_user!).and_return(true)
  end

  describe "GET /dashboards/share_card" do
    it "returns http success" do
      get share_card_dashboards_path
      expect(response).to have_http_status(:success)
    end

    it "generates QR code SVG" do
      get share_card_dashboards_path
      expect(response.body).to include('<svg')
      expect(response.body).to include('</svg>')
    end

    it "includes share URL with profile_id parameter" do
      get share_card_dashboards_path
      expect(response.body).to include("profile_id=#{profile.id}")
      expect(response.body).to include(card_path(profile.slug, profile_id: profile.id))
    end

    it "includes profile information" do
      get share_card_dashboards_path
      expect(response.body).to include(profile.full_name)
      expect(response.body).to include(profile.title)
    end

    it "includes clipboard copy functionality" do
      get share_card_dashboards_path
      expect(response.body).to include('data-controller="clipboard"')
      expect(response.body).to include('data-clipboard-target="source"')
      expect(response.body).to include('data-action="click->clipboard#copy"')
    end

    it "includes WeChat usage instructions" do
      get share_card_dashboards_path
      expect(response.body).to include('使用微信扫一扫功能')
      expect(response.body).to include('长按二维码图片')
    end

    it "has back to dashboard link" do
      get share_card_dashboards_path
      expect(response.body).to include('返回Dashboard')
      expect(response.body).to include(dashboards_path)
    end
  end

  describe "Dashboard integration" do
    it "share card route is accessible" do
      expect(share_card_dashboards_path).to eq('/dashboards/share_card')
    end
  end
end
