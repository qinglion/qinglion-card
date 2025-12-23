require 'rails_helper'

RSpec.describe "Admin::Renewals", type: :request do
  let(:admin) { create(:administrator) }
  let(:profile) { create(:profile) }

  before do
    admin_sign_in_as(admin)
  end

  describe "GET /admin/renewals" do
    it "returns http success" do
      get admin_renewals_path
      expect(response).to have_http_status(:success)
    end

    it "displays renewals list" do
      renewal = create(:renewal, profile: profile)
      get admin_renewals_path
      expect(response.body).to include(renewal.profile.full_name)
    end
  end

  describe "GET /admin/renewals/new" do
    it "returns http success" do
      get new_admin_renewal_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/renewals" do
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          profile_id: profile.id,
          payment_date: Date.today,
          amount: 1000.00,
          notes: "Test renewal"
        }
      end

      it "creates a new renewal" do
        expect {
          post admin_renewals_path, params: { renewal: valid_attributes }
        }.to change(Renewal, :count).by(1)
      end

      it "redirects to the renewals list" do
        post admin_renewals_path, params: { renewal: valid_attributes }
        expect(response).to redirect_to(admin_renewals_path)
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        {
          profile_id: nil,
          payment_date: nil,
          amount: -100
        }
      end

      it "does not create a new renewal" do
        expect {
          post admin_renewals_path, params: { renewal: invalid_attributes }
        }.not_to change(Renewal, :count)
      end

      it "returns unprocessable entity status" do
        post admin_renewals_path, params: { renewal: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /admin/renewals/:id" do
    let!(:renewal) { create(:renewal, profile: profile) }

    it "destroys the renewal" do
      expect {
        delete admin_renewal_path(renewal)
      }.to change(Renewal, :count).by(-1)
    end

    it "redirects to the renewals list" do
      delete admin_renewal_path(renewal)
      expect(response).to redirect_to(admin_renewals_path)
    end
  end
end
