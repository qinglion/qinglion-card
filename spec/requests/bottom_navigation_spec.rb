require 'rails_helper'

RSpec.describe 'Bottom Navigation', type: :request do
  let(:organization) { Organization.create!(name: 'Test Organization') }
  let(:user) { User.create!(email: 'test@example.com', password: 'password123') }
  let!(:profile) { Profile.create!(
    user: user,
    organization: organization,
    full_name: 'Test User',
    title: 'Software Engineer',
    email: 'test@example.com',
    status: 'approved',
    slug: 'test-user'
  )}

  describe 'GET /c/:slug (Card page)' do
    it 'includes bottom navigation with correct active state for card page' do
      get card_path(profile.slug)
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('data-controller="bottom-nav"')
      expect(response.body).to include('data-bottom-nav-current-page-value="card"')
      expect(response.body).to include('data-bottom-nav-target="item"')
      expect(response.body).to include('data-page="card"')
      expect(response.body).to include('data-page="team"')
      expect(response.body).to include('data-page="consultation"')
    end

    it 'home link points to the card page itself' do
      get card_path(profile.slug)
      
      expect(response.body).to include("href=\"/c/#{profile.slug}\"")
    end

    it 'team link includes profile_id parameter' do
      get card_path(profile.slug)
      
      expect(response.body).to include("href=\"/teams?profile_id=#{profile.id}\"")
    end

    it 'consultation link includes profile_id parameter' do
      get card_path(profile.slug)
      
      expect(response.body).to include("href=\"/consultations?profile_id=#{profile.id}\"")
    end
  end

  describe 'GET /teams (Teams page)' do
    it 'includes bottom navigation with correct active state for team page' do
      get teams_path(profile_id: profile.id)
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('data-controller="bottom-nav"')
      expect(response.body).to include('data-bottom-nav-current-page-value="team"')
    end

    it 'home link points back to card page when profile_id is present' do
      get teams_path(profile_id: profile.id)
      
      expect(response.body).to include("href=\"/c/#{profile.slug}?profile_id=#{profile.id}\"")
    end
  end

  describe 'GET /consultations (Consultations page)' do
    it 'includes bottom navigation with correct active state for consultation page' do
      get consultations_path(profile_id: profile.id)
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include('data-controller="bottom-nav"')
      expect(response.body).to include('data-bottom-nav-current-page-value="consultation"')
    end

    it 'home link points back to card page when profile is present' do
      get consultations_path(profile_id: profile.id)
      
      expect(response.body).to include("href=\"/c/#{profile.slug}?profile_id=#{profile.id}\"")
    end
  end
end
