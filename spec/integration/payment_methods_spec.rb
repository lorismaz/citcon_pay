# frozen_string_literal: true

RSpec.describe 'Payment Methods', :configure_citcon, :vcr do
  let(:client) { CitconPay::Client.new }

  describe 'WeChat Pay charge', vcr: { cassette_name: 'payment_methods/wechat_pay' } do
    it 'creates a WeChat Pay charge successfully' do
      response = client.charges.create(
        transaction: {
          reference: 'TEST-VCR-WECHAT-001',
          amount: 120,
          currency: 'USD',
          country: 'US',
          country_accelerator: 'CN', # Important for Chinese payment methods
          note: 'WeChat Pay VCR test'
        },
        payment: {
          method: 'wechatpay',
          client: ['mobile_browser']
        },
        urls: {
          ipn: 'https://example.com/webhooks/citcon',
          success: 'https://example.com/payment/success',
          fail: 'https://example.com/payment/fail'
        }
      )

      expect(response).to have_key('data')
      expect(response['data']).to have_key('id')
      expect(response['data']).to have_key('charge_token')
      expect(response['data']).to have_key('payment')
      expect(response['data']['payment']).to have_key('method')
      expect(response['data']['payment']['method']).to eq('wechatpay')
      expect(response['data']['status']).to eq('initiated')
    end
  end

  describe 'UnionPay charge', vcr: { cassette_name: 'payment_methods/unionpay' } do
    it 'creates a UnionPay charge with consumer information' do
      response = client.charges.create(
        transaction: {
          reference: 'TEST-VCR-UPOP-001',
          amount: 250,
          currency: 'USD',
          country: 'US',
          country_accelerator: 'CN', # Important for Chinese payment methods
          note: 'UnionPay VCR test'
        },
        payment: {
          method: 'upop',
          client: %w[mobile_browser desktop]
        },
        consumer: {
          reference: 'CUSTOMER-VCR-001',
          first_name: 'John',
          last_name: 'Doe',
          phone: '13312345678',
          email: 'john.doe@example.com'
        },
        urls: {
          ipn: 'https://example.com/webhooks/citcon',
          success: 'https://example.com/payment/success',
          fail: 'https://example.com/payment/fail'
        }
      )

      expect(response).to have_key('data')
      expect(response['data']).to have_key('id')
      expect(response['data']).to have_key('charge_token')
      expect(response['data']['payment']['method']).to eq('upop')
      expect(response['data']['status']).to eq('initiated')
    end
  end

  describe 'PayPal charge with goods and shipping', vcr: { cassette_name: 'payment_methods/paypal_with_goods' } do
    it 'creates a PayPal charge with complete goods and shipping information' do
      response = client.charges.create(
        transaction: {
          reference: 'TEST-VCR-PAYPAL-001',
          amount: 500,
          currency: 'USD',
          country: 'US',
          note: 'PayPal VCR test with goods'
        },
        payment: {
          method: 'paypal',
          client: %w[desktop mobile_browser]
        },
        goods: {
          data: [
            {
              name: 'Running Shoes',
              quantity: 2,
              unit_amount: 250.00,
              product_type: 'physical'
            }
          ],
          shipping: {
            first_name: 'John',
            last_name: 'Doe',
            phone: '6145675309',
            email: 'john.doe@example.com',
            street: '123 Main Street',
            city: 'Columbus',
            state: 'OH',
            zip: '43221',
            country: 'US'
          }
        },
        urls: {
          ipn: 'https://example.com/webhooks/citcon',
          success: 'https://example.com/payment/success',
          fail: 'https://example.com/payment/fail'
        }
      )

      expect(response).to have_key('data')
      expect(response['data']).to have_key('id')
      expect(response['data']).to have_key('charge_token')
      expect(response['data']['payment']['method']).to eq('paypal')
      expect(response['data']['status']).to eq('initiated')
      # PayPal charge created successfully
      expect(response['data']['amount']).to eq(500)
    end
  end

  describe 'PayPal charge with multiple items', vcr: { cassette_name: 'payment_methods/paypal_multiple_items' } do
    it 'creates a PayPal charge with multiple goods items' do
      response = client.charges.create(
        transaction: {
          reference: 'TEST-VCR-PAYPAL-002',
          amount: 475,
          currency: 'USD',
          country: 'US',
          note: 'PayPal multiple items test'
        },
        payment: {
          method: 'paypal',
          client: ['desktop']
        },
        goods: {
          data: [
            {
              name: 'T-Shirt',
              quantity: 3,
              unit_amount: 25.00,
              product_type: 'physical'
            },
            {
              name: 'Baseball Cap',
              quantity: 2,
              unit_amount: 200.00,
              product_type: 'physical'
            }
          ],
          shipping: {
            first_name: 'Jane',
            last_name: 'Smith',
            phone: '5551234567',
            email: 'jane.smith@example.com',
            street: '456 Oak Avenue',
            city: 'San Francisco',
            state: 'CA',
            zip: '94102',
            country: 'US'
          }
        },
        urls: {
          ipn: 'https://example.com/webhooks/citcon',
          success: 'https://example.com/payment/success',
          fail: 'https://example.com/payment/fail'
        }
      )

      expect(response).to have_key('data')
      expect(response['data']).to have_key('id')
      expect(response['data']['payment']['method']).to eq('paypal')
      expect(response['data']['status']).to eq('initiated')
    end
  end

  describe 'Alipay charge with country accelerator',
           vcr: { cassette_name: 'payment_methods/alipay_with_accelerator' } do
    it 'creates an Alipay charge with CN country accelerator' do
      response = client.charges.create(
        transaction: {
          reference: 'TEST-VCR-ALIPAY-ACC-001',
          amount: 180,
          currency: 'USD',
          country: 'US',
          country_accelerator: 'CN',
          note: 'Alipay with accelerator test'
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

      expect(response).to have_key('data')
      expect(response['data']).to have_key('id')
      expect(response['data']['payment']['method']).to eq('alipay')
      # Country accelerator is used in request but may not be in response
      expect(response['data']['country']).to eq('US')
      expect(response['data']['status']).to eq('initiated')
    end
  end
end
