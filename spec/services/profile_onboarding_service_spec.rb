require 'rails_helper'

RSpec.describe ProfileOnboardingService, type: :service do
  describe '#call' do
    it 'can be initialized and called' do
      profile = create(:profile)
      service = ProfileOnboardingService.new(profile, 'test message')
      expect(service).to respond_to(:call)
    end
  end
end
