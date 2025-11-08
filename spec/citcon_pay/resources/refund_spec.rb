# frozen_string_literal: true

RSpec.describe CitconPay::Resources::Refund, :stub do
  let(:client) { CitconPay::Client.new }
  let(:refunds) { client.refunds }

  before do
    CitconPay.configure do |c|
      c.api_key = 'test-api-key'
      c.environment = :sandbox
    end

    stub_access_token_request
  end

  describe '#create' do
    context 'with full refund' do
      it 'creates a full refund successfully' do
        transaction_id = 'test-transaction-id'

        stub_request(:post, 'https://api.sandbox.citconpay.com/v1/refunds')
          .with(
            headers: {
              'Authorization' => 'Bearer test-access-token',
              'Content-Type' => 'application/json'
            },
            body: {
              id: transaction_id,
              reference: 'REFUND-001',
              amount: 100.00,
              note: 'Full refund'
            }.to_json
          )
          .to_return(
            status: 200,
            body: {
              status: 'success',
              data: {
                id: 'refund-123',
                object: 'refund',
                reference: 'REFUND-001',
                amount: 100,
                currency: 'USD',
                status: 'succeeded',
                time_created: 1_234_567_890
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        response = refunds.create(
          id: transaction_id,
          reference: 'REFUND-001',
          amount: 100.00,
          note: 'Full refund'
        )

        expect(response).to have_key('data')
        expect(response.dig('data', 'reference')).to eq('REFUND-001')
        expect(response.dig('data', 'amount')).to eq(100)
        expect(response.dig('data', 'status')).to eq('succeeded')
      end
    end

    context 'with partial refund' do
      it 'creates a partial refund successfully' do
        transaction_id = 'test-transaction-id'

        stub_request(:post, 'https://api.sandbox.citconpay.com/v1/refunds')
          .with(
            headers: {
              'Authorization' => 'Bearer test-access-token',
              'Content-Type' => 'application/json'
            },
            body: {
              id: transaction_id,
              reference: 'REFUND-002',
              amount: 50.00,
              note: 'Partial refund'
            }.to_json
          )
          .to_return(
            status: 200,
            body: {
              status: 'success',
              data: {
                id: 'refund-124',
                object: 'refund',
                reference: 'REFUND-002',
                amount: 50,
                currency: 'USD',
                status: 'succeeded',
                time_created: 1_234_567_890
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        response = refunds.create(
          id: transaction_id,
          reference: 'REFUND-002',
          amount: 50.00,
          note: 'Partial refund'
        )

        expect(response).to have_key('data')
        expect(response.dig('data', 'reference')).to eq('REFUND-002')
        expect(response.dig('data', 'amount')).to eq(50)
        expect(response.dig('data', 'status')).to eq('succeeded')
      end
    end

    context 'with multiple partial refunds' do
      it 'creates multiple partial refunds for the same transaction' do
        transaction_id = 'test-transaction-id'

        # First refund
        stub_request(:post, 'https://api.sandbox.citconpay.com/v1/refunds')
          .with(
            headers: {
              'Authorization' => 'Bearer test-access-token',
              'Content-Type' => 'application/json'
            },
            body: {
              id: transaction_id,
              reference: 'REFUND-003',
              amount: 50.00,
              note: 'First partial refund'
            }.to_json
          )
          .to_return(
            status: 200,
            body: {
              status: 'success',
              data: {
                id: 'refund-125',
                object: 'refund',
                reference: 'REFUND-003',
                amount: 50,
                currency: 'USD',
                status: 'succeeded',
                time_created: 1_234_567_890
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        first_response = refunds.create(
          id: transaction_id,
          reference: 'REFUND-003',
          amount: 50.00,
          note: 'First partial refund'
        )

        expect(first_response.dig('data', 'reference')).to eq('REFUND-003')

        # Second refund
        stub_request(:post, 'https://api.sandbox.citconpay.com/v1/refunds')
          .with(
            headers: {
              'Authorization' => 'Bearer test-access-token',
              'Content-Type' => 'application/json'
            },
            body: {
              id: transaction_id,
              reference: 'REFUND-004',
              amount: 50.00,
              note: 'Second partial refund'
            }.to_json
          )
          .to_return(
            status: 200,
            body: {
              status: 'success',
              data: {
                id: 'refund-126',
                object: 'refund',
                reference: 'REFUND-004',
                amount: 50,
                currency: 'USD',
                status: 'succeeded',
                time_created: 1_234_567_891
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        second_response = refunds.create(
          id: transaction_id,
          reference: 'REFUND-004',
          amount: 50.00,
          note: 'Second partial refund'
        )

        expect(second_response.dig('data', 'reference')).to eq('REFUND-004')
      end
    end

    context 'with errors' do
      it 'raises error when refund fails' do
        transaction_id = 'test-transaction-id'

        stub_request(:post, 'https://api.sandbox.citconpay.com/v1/refunds')
          .to_return(
            status: 406,
            body: {
              status: 'fail',
              message: 'refund failed',
              data: {
                code: '4202',
                message: 'refund failed'
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        expect do
          refunds.create(
            id: transaction_id,
            reference: 'REFUND-FAIL',
            amount: 100.00,
            note: 'Failed refund'
          )
        end.to raise_error(CitconPay::APIError, 'refund failed')
      end
    end
  end
end
