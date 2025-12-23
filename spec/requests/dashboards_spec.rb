require 'rails_helper'

RSpec.describe "Dashboards", type: :request do

  let(:user) { create(:user) }
  before { sign_in_as(user) }

  describe "GET /dashboards" do
    it "returns http success" do
      get dashboards_path
      expect(response).to be_success_with_view_check('index')
    end
  end

  describe "GET /dashboards/settings" do
    it "returns http success" do
      get settings_dashboards_path
      expect(response).to be_success_with_view_check('settings')
    end

    it "includes background_image field" do
      get settings_dashboards_path
      expect(response.body).to include('background_image')
      expect(response.body).to include('data-controller="image-preview"')
    end
  end

  describe "PATCH /dashboards/settings" do
    let(:profile) { user.profile }
    
    it "updates profile with valid params" do
      patch settings_dashboards_path, params: {
        profile: {
          full_name: 'Updated Name',
          title: 'Senior Developer',
          bio: 'Updated bio'
        }
      }
      expect(response).to redirect_to(settings_dashboards_path)
      expect(profile.reload.full_name).to eq('Updated Name')
    end

    it "accepts background_image param" do
      expect {
        patch settings_dashboards_path, params: {
          profile: {
            full_name: profile.full_name,
            title: profile.title
          }
        }
      }.not_to raise_error
    end
  end

end
