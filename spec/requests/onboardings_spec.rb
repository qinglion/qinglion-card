require 'rails_helper'

RSpec.describe "Onboardings", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /onboardings" do
    it "returns http success" do
      get onboardings_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "POST /onboardings/skip" do
    it "marks onboarding as completed and redirects to dashboard" do
      profile = user.profile
      expect(profile.onboarding_completed).to be_falsey

      post skip_onboardings_path
      
      profile.reload
      expect(profile.onboarding_completed).to be_truthy
      expect(profile.onboarding_step).to eq('skipped')
      expect(response).to redirect_to(dashboards_path)
      follow_redirect!
      expect(response.body).to include('已跳过名片设置')
    end
  end

end
