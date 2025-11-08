# frozen_string_literal: true

RSpec.describe 'Charge', :configure_citcon, :vcr do
  let(:client) { CitconPay::Client.new }

  describe 'creating a charge', vcr: { cassette_name: 'charge/create_alipay' } do
    it 'creates an Alipay charge successfully' do
      charge_data = {
        transaction: {
          reference: 'TEST-VCR-ALIPAY-001',
          amount: 100,
          currency: 'USD',
          country: 'US',
          note: 'VCR Test Payment'
        },
        payment: {
          method: 'alipay',
          client: %w[mobile_browser desktop]
        },
        urls: {
          ipn: 'https://example.com/webhooks/citcon',
          success: 'https://example.com/payment/success',
          fail: 'https://example.com/payment/fail',
          cancel: 'https://example.com/payment/cancel'
        }
      }

      response = client.post('charges', body: charge_data)

      expect(response).to have_key('data')
      expect(response['data']).to have_key('id')
      expect(response['data']).to have_key('charge_token')
      expect(response['data']).to have_key('payment')
      expect(response['data']['status']).to eq('initiated')
      expect(response['data']['payment']).to have_key('client')
      expect(response['data']['payment']['client']).to be_an(Array)
      expect(response['data']['payment']['client'].first).to have_key('content')
    end
  end
end
