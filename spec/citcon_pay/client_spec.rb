# frozen_string_literal: true

RSpec.describe CitconPay::Client, :configure_citcon, :stub do
  let(:client) { described_class.new }

  describe '#initialize' do
    it 'uses global configuration by default' do
      expect(client.configuration).to eq(CitconPay.configuration)
    end

    it 'accepts custom configuration' do
      custom_config = CitconPay::Configuration.new
      custom_config.api_key = 'custom-key'
      custom_config.environment = :production

      custom_client = described_class.new(custom_config)

      expect(custom_client.configuration).to eq(custom_config)
      expect(custom_client.configuration.api_key).to eq('custom-key')
      expect(custom_client.configuration.environment).to eq(:production)
    end

    it 'validates configuration on initialization' do
      invalid_config = CitconPay::Configuration.new

      expect do
        described_class.new(invalid_config)
      end.to raise_error(CitconPay::ConfigurationError)
    end
  end

  describe '#authenticate!' do
    it 'obtains and stores access token' do
      stub_access_token_request

      token = client.authenticate!

      expect(token).to eq('test-access-token')
      expect(client.access_token).to eq('test-access-token')
      expect(client.authenticated?).to be true
    end

    it 'raises error when authentication fails' do
      stub_request(:post, 'https://api.sandbox.citconpay.com/v1/access-tokens')
        .to_return(status: 401, body: { error: 'Invalid API key' }.to_json)

      expect { client.authenticate! }.to raise_error(CitconPay::AuthenticationError)
    end
  end

  describe 'resource accessors' do
    it 'provides access to access_tokens resource' do
      expect(client.access_tokens).to be_a(CitconPay::Resources::AccessToken)
    end

    it 'provides access to charges resource' do
      expect(client.charges).to be_a(CitconPay::Resources::Charge)
    end

    it 'provides access to refunds resource' do
      expect(client.refunds).to be_a(CitconPay::Resources::Refund)
    end

    it 'provides access to cancels resource' do
      expect(client.cancels).to be_a(CitconPay::Resources::Cancel)
    end

    it 'provides access to transactions resource' do
      expect(client.transactions).to be_a(CitconPay::Resources::Transaction)
    end
  end

  describe 'HTTP methods' do
    before do
      stub_access_token_request
    end

    describe '#post' do
      it 'makes POST request with authentication' do
        charge_data = {
          transaction: { reference: 'TEST', amount: 100, currency: 'USD', country: 'US' },
          payment: { method: 'alipay', client: ['mobile_browser'] },
          urls: { ipn: 'https://example.com/ipn' }
        }

        stub_charge_request(charge_data: charge_data)

        response = client.post('charges', body: charge_data)

        expect(response).to have_key('data')
        expect(response.dig('data', 'id')).to eq('test-charge-id')
      end

      it 'authenticates automatically before request' do
        expect(client.authenticated?).to be false

        stub_access_token_request
        stub_charge_request

        client.post('charges', body: {})

        expect(client.authenticated?).to be true
      end
    end

    describe '#get' do
      it 'makes GET request with authentication' do
        stub_transaction_request(transaction_id: '123')

        response = client.get('transactions/123')

        expect(response.dig('data', 'id')).to eq('123')
      end
    end
  end

  describe 'error handling' do
    before do
      stub_access_token_request
    end

    it 'raises ValidationError for 400 status' do
      stub_request(:post, 'https://api.sandbox.citconpay.com/v1/charges')
        .to_return(
          status: 400,
          body: { message: 'Invalid parameters' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        client.post('charges', body: {})
      end.to raise_error(CitconPay::ValidationError, 'Invalid parameters')
    end

    it 'raises NotFoundError for 404 status' do
      stub_request(:get, 'https://api.sandbox.citconpay.com/v1/transactions/nonexistent')
        .to_return(
          status: 404,
          body: { message: 'Transaction not found' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        client.get('transactions/nonexistent')
      end.to raise_error(CitconPay::NotFoundError, 'Transaction not found')
    end

    it 'raises RateLimitError for 429 status' do
      stub_request(:post, 'https://api.sandbox.citconpay.com/v1/charges')
        .to_return(
          status: 429,
          body: { message: 'Rate limit exceeded' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        client.post('charges', body: {})
      end.to raise_error(CitconPay::RateLimitError, 'Rate limit exceeded')
    end

    it 'raises ServerError for 500 status' do
      stub_request(:post, 'https://api.sandbox.citconpay.com/v1/charges')
        .to_return(
          status: 500,
          body: { message: 'Internal server error' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      expect do
        client.post('charges', body: {})
      end.to raise_error(CitconPay::ServerError, 'Internal server error')
    end

    it 'clears access token on 401 error' do
      client.authenticate!
      expect(client.authenticated?).to be true

      stub_request(:get, 'https://api.sandbox.citconpay.com/v1/transactions/123')
        .to_return(status: 401, body: { message: 'Unauthorized' }.to_json)

      expect do
        client.get('transactions/123')
      end.to raise_error(CitconPay::AuthenticationError)

      expect(client.authenticated?).to be false
    end
  end
end
