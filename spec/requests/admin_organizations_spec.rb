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
end
