# frozen_string_literal: true

RSpec.describe CitconPay::Resources::Charge, :stub do
  let(:client) { CitconPay::Client.new }
  let(:charges) { client.charges }

  before do
    CitconPay.configure do |c|
      c.api_key = 'test-api-key'
      c.environment = :sandbox
    end

    stub_access_token_request
  end

  let(:transaction) do
    { reference: 'ORDER-123', amount: 100.00, currency: 'USD', country: 'US' }
  end
  let(:payment) { { method: 'wechatpay', client: ['mobile_browser'] } }
  let(:urls) do
    { ipn: 'https://example.com/ipn', success: 'https://example.com/success', fail: 'https://example.com/fail' }
  end

  let(:success_response) do
    {
      status: 'success',
      data: { id: 'charge-123', object: 'charge', reference: 'ORDER-123', status: 'pending' }
    }.to_json
  end

  describe '#create' do
    it 'forwards the ext payload under the body ext key' do
      stub = stub_request(:post, 'https://api.sandbox.citconpay.com/v1/charges')
             .with(
               body: {
                 transaction: transaction,
                 payment: payment,
                 urls: urls,
                 ext: { device: { os: 'ios' } }
               }.to_json
             )
             .to_return(status: 200, body: success_response, headers: { 'Content-Type' => 'application/json' })

      charges.create(
        transaction: transaction,
        payment: payment,
        urls: urls,
        ext: { device: { os: 'ios' } }
      )

      expect(stub).to have_been_requested
    end

    it 'omits the ext key when ext is nil' do
      stub = stub_request(:post, 'https://api.sandbox.citconpay.com/v1/charges')
             .with(body: { transaction: transaction, payment: payment, urls: urls }.to_json)
             .to_return(status: 200, body: success_response, headers: { 'Content-Type' => 'application/json' })

      charges.create(transaction: transaction, payment: payment, urls: urls)

      expect(stub).to have_been_requested
    end
  end
end
