# frozen_string_literal: true

RSpec.describe 'Refunds', :configure_citcon, :vcr do
  let(:client) { CitconPay::Client.new }

  # NOTE: Refund tests use a completed PayPal transaction that was manually
  # completed in sandbox and captured before refunding. PayPal transactions
  # require: charge -> authorize -> capture -> refund workflow.
  # The cassettes were recorded after completing this full flow.

  describe 'creating a full refund', vcr: { cassette_name: 'refund/create_full_refund_success' } do
    it 'creates a full refund successfully on a captured transaction' do
      # This test uses a pre-recorded cassette of a full refund
      # The original flow was:
      # 1. Create PayPal charge (TEST-VCR-PAYPAL-REFUND-005)
      # 2. Complete payment manually in PayPal sandbox
      # 3. Capture the authorized transaction (ID: 2000470574698110676997)
      # 4. Refund the captured transaction

      # Create a full refund on the captured transaction
      refund_response = client.refunds.create(
        id: '2000470574698110676997', # Capture transaction ID
        reference: 'REFUND-PAYPAL-005',
        amount: 100.00,
        note: 'Test refund for TEST-VCR-PAYPAL-REFUND-005'
      )

      expect(refund_response).to have_key('data')
      expect(refund_response['data']).to have_key('id')
      expect(refund_response['data']).to have_key('reference')
      expect(refund_response['data']['reference']).to eq('REFUND-PAYPAL-005')
      expect(refund_response['data']).to have_key('amount')
      expect(refund_response['data']['amount']).to eq(100)
      expect(refund_response['data']['status']).to eq('succeeded')
    end
  end

  # Additional refund scenarios (partial refunds, multiple refunds) are tested
  # in spec/citcon_pay/resources/refund_spec.rb using stubs, as they follow
  # the same workflow and don't require additional manual payment completions.
end
