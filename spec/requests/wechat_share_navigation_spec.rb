require 'rails_helper'

RSpec.describe 'WeChat Share Navigation', type: :request do
  let(:organization) { Organization.create!(name: 'Test Organization') }
  
  let!(:source_profile) { Profile.create!(
    user: User.create!(email: 'source@example.com', password: 'password123'),
    organization: organization,
    full_name: 'Source User',
    title: 'Manager',
    email: 'source@example.com',
    status: 'approved',
    slug: 'source-user'
  )}
  
  let!(:other_profile) { Profile.create!(
    user: User.create!(email: 'other@example.com', password: 'password123'),
    organization: organization,
    full_name: 'Other User',
    title: 'Engineer',
    email: 'other@example.com',
    status: 'approved',
    slug: 'other-user'
  )}

  describe 'Visiting shared card with profile_id parameter' do
    context 'GET /c/:slug?profile_id=X' do
      it 'activates home button when viewing source profile (matching profile_id)' do
        get card_path(source_profile.slug, profile_id: source_profile.id)
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include('data-bottom-nav-current-page-value="card"')
      end

      it 'does NOT activate home button when viewing other profile' do
        get card_path(other_profile.slug, profile_id: source_profile.id)
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include('data-bottom-nav-current-page-value="none"')
      end

      it 'home button on source profile links to itself with profile_id' do
        get card_path(source_profile.slug, profile_id: source_profile.id)
        
        expect(response.body).to include("href=\"/c/#{source_profile.slug}?profile_id=#{source_profile.id}\"")
      end

      it 'home button on other profile links back to source profile' do
        get card_path(other_profile.slug, profile_id: source_profile.id)
        
        expect(response.body).to include("href=\"/c/#{source_profile.slug}?profile_id=#{source_profile.id}\"")
      end

      it 'preserves profile_id in team navigation link' do
        get card_path(other_profile.slug, profile_id: source_profile.id)
        
        expect(response.body).to include("href=\"/teams?profile_id=#{source_profile.id}\"")
      end

      it 'preserves profile_id in consultation navigation link' do
        get card_path(other_profile.slug, profile_id: source_profile.id)
        
        expect(response.body).to include("href=\"/consultations?profile_id=#{source_profile.id}\"")
      end
    end

    context 'GET /teams?profile_id=X' do
      it 'member cards include profile_id parameter in links' do
        get teams_path(profile_id: source_profile.id)
        
        expect(response).to have_http_status(:success)
        # Check that member cards include profile_id parameter
        expect(response.body).to match(/href="\/c\/[^"]+\?profile_id=#{source_profile.id}"/)
      end

      it 'home button links back to source profile with profile_id' do
        get teams_path(profile_id: source_profile.id)
        
        expect(response.body).to include("href=\"/c/#{source_profile.slug}?profile_id=#{source_profile.id}\"")
      end
    end

    context 'Direct visit without profile_id' do
      it 'activates home button when viewing own card' do
        get card_path(source_profile.slug)
        
        expect(response).to have_http_status(:success)
        expect(response.body).to include('data-bottom-nav-current-page-value="card"')
      end

      it 'home button links to current card' do
        get card_path(source_profile.slug)
        
        expect(response.body).to include("href=\"/c/#{source_profile.slug}\"")
      end

      it 'navigation links use current profile id' do
        get card_path(source_profile.slug)
        
        expect(response.body).to include("href=\"/teams?profile_id=#{source_profile.id}\"")
        expect(response.body).to include("href=\"/consultations?profile_id=#{source_profile.id}\"")
      end
    end
  end

  describe 'Navigation flow in share scenario' do
    it 'maintains profile_id and correct activation throughout navigation chain' do
      # Step 1: User B visits shared link from User A (source profile)
      get card_path(source_profile.slug, profile_id: source_profile.id)
      expect(response.body).to include('data-bottom-nav-current-page-value="card"')
      
      # Step 2: Go to teams from source profile
      get teams_path(profile_id: source_profile.id)
      expect(response.body).to include('data-bottom-nav-current-page-value="team"')
      
      # Step 3: Click another member's card with profile_id
      get card_path(other_profile.slug, profile_id: source_profile.id)
      expect(response.body).to include('data-bottom-nav-current-page-value="none"')
      expect(response.body).to include("href=\"/c/#{source_profile.slug}?profile_id=#{source_profile.id}\"")
      
      # Step 4: Click home to return to source profile
      get card_path(source_profile.slug, profile_id: source_profile.id)
      expect(response.body).to include('data-bottom-nav-current-page-value="card"')
    end

    it 'returns to source from teams page with home activated' do
      # Step 1: Visit shared source profile
      get card_path(source_profile.slug, profile_id: source_profile.id)
      expect(response.body).to include('data-bottom-nav-current-page-value="card"')
      
      # Step 2: Go to teams
      get teams_path(profile_id: source_profile.id)
      expect(response.body).to include('data-bottom-nav-current-page-value="team"')
      
      # Step 3: Click home from teams page - returns to source with home activated
      get card_path(source_profile.slug, profile_id: source_profile.id)
      expect(response.body).to include('data-bottom-nav-current-page-value="card"')
    end
  end
end
