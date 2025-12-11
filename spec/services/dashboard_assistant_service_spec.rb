require 'rails_helper'

RSpec.describe DashboardAssistantService, type: :service do
  describe '#call' do
    it 'can be initialized and called' do
      profile = create(:profile)
      service = DashboardAssistantService.new(profile, 'test message')
      expect(service).to respond_to(:call)
    end
  end
end
