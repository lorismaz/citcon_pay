# frozen_string_literal: true

RSpec.describe 'Authentication', :configure_citcon, :vcr do
  let(:client) { CitconPay::Client.new }

  describe 'obtaining access token', vcr: { cassette_name: 'authentication/access_token_success' } do
    it 'authenticates successfully with valid API key' do
      client.authenticate!

      expect(client.authenticated?).to be true
      expect(client.access_token).not_to be_nil
      expect(client.access_token).to be_a(String)
    end
  end
end
