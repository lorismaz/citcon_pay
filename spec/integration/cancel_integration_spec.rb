# frozen_string_literal: true

RSpec.describe 'Cancels', :configure_citcon, :vcr do
  let(:client) { CitconPay::Client.new }

  describe 'canceling a transaction', vcr: { cassette_name: 'cancel/create_cancel' } do
    it 'cancels a transaction successfully' do
      # Create a charge to cancel
      charge_response = client.charges.create(
        transaction: {
          reference: 'TEST-VCR-CANCEL-001',
          amount: 150,
          currency: 'USD',
          country: 'US',
          note: 'Cancel test payment'
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
      )

      transaction_id = charge_response.dig('data', 'id')

      # Cancel the transaction
      cancel_response = client.cancels.create(
        id: transaction_id,
        reference: 'CANCEL-REQ-001',
        transaction_reference: 'TEST-VCR-CANCEL-001'
      )

      expect(cancel_response).to have_key('data')
      expect(cancel_response['data']).to have_key('id')
      expect(cancel_response['data']).to have_key('reference')
      expect(cancel_response['data']['reference']).to eq('CANCEL-REQ-001')
    end
  end

  describe 'canceling with minimal information', vcr: { cassette_name: 'cancel/create_cancel_minimal' } do
    it 'cancels a transaction with only required fields' do
      # Create a charge
      charge_response = client.charges.create(
        transaction: {
          reference: 'TEST-VCR-CANCEL-002',
          amount: 75,
          currency: 'USD',
          country: 'US',
          note: 'Minimal cancel test'
        },
        payment: {
          method: 'alipay',
          client: ['mobile_browser']
        },
        urls: {
          ipn: 'https://example.com/webhooks/citcon',
          success: 'https://example.com/payment/success',
          fail: 'https://example.com/payment/fail'
        }
      )

      transaction_id = charge_response.dig('data', 'id')

      # Cancel with minimal data (no transaction_reference)
      cancel_response = client.cancels.create(
        id: transaction_id,
        reference: 'CANCEL-REQ-002'
      )

      expect(cancel_response).to have_key('data')
      expect(cancel_response['data']).to have_key('id')
      expect(cancel_response['data']['reference']).to eq('CANCEL-REQ-002')
    end
  end
end
