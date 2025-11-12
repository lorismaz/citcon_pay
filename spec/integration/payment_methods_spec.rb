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

  # Service product type tests - verifying that service products don't require shipping addresses
  describe 'Alipay charge with service product type (no shipping)',
           vcr: { cassette_name: 'charge/alipay_service_no_shipping' } do
    it 'creates an Alipay charge with service product type without shipping address' do
      response = client.charges.create(
        transaction: {
          reference: 'ALIPAY-SERVICE-1762634608',
          amount: 150.00,
          currency: 'USD',
          country: 'US',
          country_accelerator: 'CN',
          note: 'Test payment for consulting service'
        },
        payment: {
          method: 'alipay',
          client: %w[mobile_browser desktop]
        },
        consumer: {
          reference: 'CUSTOMER-SERVICE-001',
          first_name: 'Jane',
          last_name: 'Smith',
          phone: '13312345678',
          email: 'jane.smith@example.com'
        },
        urls: {
          ipn: 'https://example.com/webhooks/citcon',
          success: 'https://example.com/payment/success',
          fail: 'https://example.com/payment/fail',
          cancel: 'https://example.com/payment/cancel'
        },
        goods: {
          data: [
            {
              product_name: 'Business Consulting Service',
              product_sku: 'SERVICE-CONSULT-001',
              product_type: 'service', # Service type - no shipping required
              quantity: 1,
              unit_amount: 150.00,
              description: 'Professional business consulting - 3 hours'
            }
          ]
          # Note: No shipping parameter included - this is the key test
        }
      )

      # Verify successful charge creation
      expect(response).to have_key('data')
      expect(response['data']).to have_key('id')
      expect(response['data']).to have_key('charge_token')
      expect(response['data']['payment']['method']).to eq('alipay')
      expect(response['data']['status']).to eq('initiated')
      expect(response['data']['amount']).to eq(150)
      expect(response['data']['currency']).to eq('USD')

      # Verify payment URLs are provided
      expect(response['data']['payment']).to have_key('client')
      expect(response['data']['payment']['client']).to be_an(Array)
      expect(response['data']['payment']['client']).not_to be_empty
    end
  end

  describe 'WeChat Pay charge with service product type (no shipping)',
           vcr: { cassette_name: 'charge/wechat_service_no_shipping' } do
    it 'creates a WeChat Pay charge with service product type without shipping address' do
      response = client.charges.create(
        transaction: {
          reference: 'WECHAT-SERVICE-1762634628',
          amount: 99.00,
          currency: 'USD',
          country: 'US',
          country_accelerator: 'CN',
          note: 'Test payment for premium subscription'
        },
        payment: {
          method: 'wechatpay',
          client: %w[mobile_browser desktop]
        },
        consumer: {
          reference: 'CUSTOMER-SERVICE-002',
          first_name: 'Michael',
          last_name: 'Chen',
          phone: '13312345678',
          email: 'michael.chen@example.com'
        },
        urls: {
          ipn: 'https://example.com/webhooks/citcon',
          success: 'https://example.com/payment/success',
          fail: 'https://example.com/payment/fail',
          cancel: 'https://example.com/payment/cancel'
        },
        goods: {
          data: [
            {
              product_name: 'Premium Subscription - Annual',
              product_sku: 'SERVICE-SUB-PREMIUM-ANNUAL',
              product_type: 'service', # Service type - no shipping required
              quantity: 1,
              unit_amount: 99.00,
              description: 'Premium membership for 12 months with all features unlocked'
            }
          ]
          # Note: No shipping parameter included - this is the key test
        }
      )

      # Verify successful charge creation
      expect(response).to have_key('data')
      expect(response['data']).to have_key('id')
      expect(response['data']).to have_key('charge_token')
      expect(response['data']['payment']['method']).to eq('wechatpay')
      expect(response['data']['status']).to eq('initiated')
      expect(response['data']['amount']).to eq(99)
      expect(response['data']['currency']).to eq('USD')

      # Verify payment URLs are provided
      expect(response['data']['payment']).to have_key('client')
      expect(response['data']['payment']['client']).to be_an(Array)
      expect(response['data']['payment']['client']).not_to be_empty
    end
  end

  # Comprehensive service address combination tests
  describe 'Service product address flexibility tests' do
    describe 'no billing, no shipping',
             vcr: { cassette_name: 'service_address_tests/no_billing_no_shipping' } do
      it 'creates a charge with service type and NO addresses at all' do
        response = client.charges.create(
          transaction: {
            reference: 'SERVICE-NO-ADDR-1762636004',
            amount: 100.00,
            currency: 'USD',
            country: 'US',
            country_accelerator: 'CN',
            note: 'Service with no addresses'
          },
          payment: {
            method: 'alipay',
            client: %w[mobile_browser desktop]
          },
          consumer: {
            reference: 'CUSTOMER-001',
            first_name: 'Test',
            last_name: 'User',
            phone: '13312345678',
            email: 'test@example.com'
          },
          urls: {
            ipn: 'https://example.com/webhooks/citcon',
            success: 'https://example.com/payment/success',
            fail: 'https://example.com/payment/fail',
            cancel: 'https://example.com/payment/cancel'
          },
          goods: {
            data: [
              {
                product_name: 'SaaS Subscription',
                product_sku: 'SERVICE-001',
                product_type: 'service',
                quantity: 1,
                unit_amount: 100.00,
                description: 'Monthly subscription service'
              }
            ]
            # No billing, no shipping
          }
        )

        expect(response['data']).to have_key('id')
        expect(response['data']['status']).to eq('initiated')
        expect(response['data']['amount']).to eq(100)
      end
    end

    describe 'billing only, no shipping',
             vcr: { cassette_name: 'service_address_tests/billing_only_no_shipping' } do
      it 'creates a charge with service type and billing address only' do
        response = client.charges.create(
          transaction: {
            reference: 'SERVICE-BILL-ONLY-1762636005',
            amount: 100.00,
            currency: 'USD',
            country: 'US',
            country_accelerator: 'CN',
            note: 'Service with billing address only'
          },
          payment: {
            method: 'alipay',
            client: %w[mobile_browser desktop]
          },
          consumer: {
            reference: 'CUSTOMER-001',
            first_name: 'Test',
            last_name: 'User',
            phone: '13312345678',
            email: 'test@example.com'
          },
          urls: {
            ipn: 'https://example.com/webhooks/citcon',
            success: 'https://example.com/payment/success',
            fail: 'https://example.com/payment/fail',
            cancel: 'https://example.com/payment/cancel'
          },
          goods: {
            data: [
              {
                product_name: 'SaaS Subscription',
                product_sku: 'SERVICE-001',
                product_type: 'service',
                quantity: 1,
                unit_amount: 100.00,
                description: 'Monthly subscription service'
              }
            ],
            billing: {
              first_name: 'Bill',
              last_name: 'Payer',
              phone: '2125551234',
              email: 'billing@company.com',
              street: '100 Billing Street',
              city: 'New York',
              state: 'NY',
              zip: '10001',
              country: 'US'
            }
            # Billing only, no shipping
          }
        )

        expect(response['data']).to have_key('id')
        expect(response['data']['status']).to eq('initiated')
        expect(response['data']['amount']).to eq(100)
      end
    end

    describe 'shipping only, no billing',
             vcr: { cassette_name: 'service_address_tests/shipping_only_no_billing' } do
      it 'creates a charge with service type and shipping address only' do
        response = client.charges.create(
          transaction: {
            reference: 'SERVICE-SHIP-ONLY-1762636005',
            amount: 100.00,
            currency: 'USD',
            country: 'US',
            country_accelerator: 'CN',
            note: 'Service with shipping address only'
          },
          payment: {
            method: 'alipay',
            client: %w[mobile_browser desktop]
          },
          consumer: {
            reference: 'CUSTOMER-001',
            first_name: 'Test',
            last_name: 'User',
            phone: '13312345678',
            email: 'test@example.com'
          },
          urls: {
            ipn: 'https://example.com/webhooks/citcon',
            success: 'https://example.com/payment/success',
            fail: 'https://example.com/payment/fail',
            cancel: 'https://example.com/payment/cancel'
          },
          goods: {
            data: [
              {
                product_name: 'SaaS Subscription',
                product_sku: 'SERVICE-001',
                product_type: 'service',
                quantity: 1,
                unit_amount: 100.00,
                description: 'Monthly subscription service'
              }
            ],
            shipping: {
              first_name: 'Ship',
              last_name: 'Receiver',
              phone: '6145675309',
              email: 'shipping@company.com',
              street: '200 Shipping Ave',
              city: 'Columbus',
              state: 'OH',
              zip: '43221',
              country: 'US'
            }
            # Shipping only, no billing
          }
        )

        expect(response['data']).to have_key('id')
        expect(response['data']['status']).to eq('initiated')
        expect(response['data']['amount']).to eq(100)
      end
    end

    describe 'both billing and shipping',
             vcr: { cassette_name: 'service_address_tests/both_billing_and_shipping' } do
      it 'creates a charge with service type and both addresses' do
        response = client.charges.create(
          transaction: {
            reference: 'SERVICE-BOTH-ADDR-1762636006',
            amount: 100.00,
            currency: 'USD',
            country: 'US',
            country_accelerator: 'CN',
            note: 'Service with both billing and shipping'
          },
          payment: {
            method: 'alipay',
            client: %w[mobile_browser desktop]
          },
          consumer: {
            reference: 'CUSTOMER-001',
            first_name: 'Test',
            last_name: 'User',
            phone: '13312345678',
            email: 'test@example.com'
          },
          urls: {
            ipn: 'https://example.com/webhooks/citcon',
            success: 'https://example.com/payment/success',
            fail: 'https://example.com/payment/fail',
            cancel: 'https://example.com/payment/cancel'
          },
          goods: {
            data: [
              {
                product_name: 'SaaS Subscription',
                product_sku: 'SERVICE-001',
                product_type: 'service',
                quantity: 1,
                unit_amount: 100.00,
                description: 'Monthly subscription service'
              }
            ],
            billing: {
              first_name: 'Bill',
              last_name: 'Payer',
              phone: '2125551234',
              email: 'billing@company.com',
              street: '100 Billing Street',
              city: 'New York',
              state: 'NY',
              zip: '10001',
              country: 'US'
            },
            shipping: {
              first_name: 'Ship',
              last_name: 'Receiver',
              phone: '6145675309',
              email: 'shipping@company.com',
              street: '200 Shipping Ave',
              city: 'Columbus',
              state: 'OH',
              zip: '43221',
              country: 'US'
            }
            # Both billing and shipping
          }
        )

        expect(response['data']).to have_key('id')
        expect(response['data']['status']).to eq('initiated')
        expect(response['data']['amount']).to eq(100)
      end
    end
  end
end
