# frozen_string_literal: true

RSpec.describe 'Refunds', :configure_citcon, :vcr do
  let(:client) { CitconPay::Client.new }

  # NOTE: Refund tests are commented out because refunds require transactions
  # to be in 'success' status, which requires actual payment completion.
  # In sandbox environment, transactions remain in 'initiated' status unless
  # the payment flow is completed manually.

  describe 'creating a full refund', vcr: { cassette_name: 'refund/create_full_refund' }, skip: true do
    it 'creates a full refund successfully' do
      # First create a charge to refund
      charge_response = client.charges.create(
        transaction: {
          reference: 'TEST-VCR-REFUND-001',
          amount: 100,
          currency: 'USD',
          country: 'US',
          note: 'Full refund test payment'
        },
        payment: {
          method: 'alipay',
          client: %w[mobile_browser desktop]
        },
        urls: {
          ipn: 'https://example.com/webhooks/citcon',
          success: 'https://example.com/payment/success',
          fail: 'https://example.com/payment/fail'
        }
      )

      transaction_id = charge_response.dig('data', 'id')

      # Create a full refund
      refund_response = client.refunds.create(
        id: transaction_id,
        reference: 'REFUND-FULL-001',
        transaction_reference: 'TEST-VCR-REFUND-001',
        amount: 100.00,
        note: 'Customer requested full refund'
      )

      expect(refund_response).to have_key('data')
      expect(refund_response['data']).to have_key('id')
      expect(refund_response['data']).to have_key('reference')
      expect(refund_response['data']['reference']).to eq('REFUND-FULL-001')
      expect(refund_response['data']).to have_key('amount')
    end
  end

  describe 'creating a partial refund', vcr: { cassette_name: 'refund/create_partial_refund' }, skip: true do
    it 'creates a partial refund successfully' do
      # Create a charge to partially refund
      charge_response = client.charges.create(
        transaction: {
          reference: 'TEST-VCR-REFUND-002',
          amount: 200,
          currency: 'USD',
          country: 'US',
          note: 'Partial refund test payment'
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

      # Create a partial refund (50% of original amount)
      refund_response = client.refunds.create(
        id: transaction_id,
        reference: 'REFUND-PARTIAL-001',
        amount: 100.00,
        note: 'Partial refund for one item'
      )

      expect(refund_response).to have_key('data')
      expect(refund_response['data']).to have_key('id')
      expect(refund_response['data']).to have_key('reference')
      expect(refund_response['data']['reference']).to eq('REFUND-PARTIAL-001')
    end
  end

  describe 'creating multiple partial refunds', vcr: { cassette_name: 'refund/create_multiple_partial_refunds' },
                                                skip: true do
    it 'creates multiple partial refunds for the same transaction' do
      # Create a charge
      charge_response = client.charges.create(
        transaction: {
          reference: 'TEST-VCR-REFUND-003',
          amount: 300,
          currency: 'USD',
          country: 'US',
          note: 'Multiple partial refunds test'
        },
        payment: {
          method: 'alipay',
          client: ['desktop']
        },
        urls: {
          ipn: 'https://example.com/webhooks/citcon',
          success: 'https://example.com/payment/success',
          fail: 'https://example.com/payment/fail'
        }
      )

      transaction_id = charge_response.dig('data', 'id')

      # First partial refund
      first_refund = client.refunds.create(
        id: transaction_id,
        reference: 'REFUND-PARTIAL-002',
        amount: 100.00,
        note: 'First partial refund'
      )

      expect(first_refund['data']).to have_key('id')
      expect(first_refund['data']['reference']).to eq('REFUND-PARTIAL-002')

      # Second partial refund
      second_refund = client.refunds.create(
        id: transaction_id,
        reference: 'REFUND-PARTIAL-003',
        amount: 100.00,
        note: 'Second partial refund'
      )

      expect(second_refund['data']).to have_key('id')
      expect(second_refund['data']['reference']).to eq('REFUND-PARTIAL-003')
    end
  end
end
