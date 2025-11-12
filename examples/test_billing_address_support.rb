#!/usr/bin/env ruby
# frozen_string_literal: true

# This script tests if the Citcon API accepts a billing address field
# and if it's required for physical vs service products

require 'bundler/setup'
require 'citcon_pay'
require 'vcr'
require 'webmock'

# Configure VCR
VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true
  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i[method uri body]
  }
  config.filter_sensitive_data('<API_KEY>') { ENV['CITCON_API_KEY'] }
  config.filter_sensitive_data('<ACCESS_TOKEN>') do |interaction|
    auth_header = interaction.request.headers['Authorization']&.first
    auth_header.gsub(/^Bearer /, '') if auth_header && auth_header.start_with?('Bearer ')
  end
end

# Configure CitconPay
CitconPay.configure do |config|
  config.api_key = ENV.fetch('CITCON_API_KEY', 'sk-uat-d5ecc6d9bdd0c729fe8481438590221c')
  config.environment = :sandbox
  config.log_level = :info
end

client = CitconPay::Client.new

puts '=' * 80
puts 'Test 1: Alipay charge with billing address field (physical product)'
puts '=' * 80

# Test 1: Try adding a billing address field with physical product
VCR.use_cassette('billing_tests/alipay_physical_with_billing', record: :new_episodes) do
  begin
    response = client.charges.create(
      transaction: {
        reference: "BILLING-TEST-PHYSICAL-#{Time.now.to_i}",
        amount: 100.00,
        currency: 'USD',
        country: 'US',
        country_accelerator: 'CN',
        note: 'Testing billing address support'
      },
      payment: {
        method: 'alipay',
        client: %w[mobile_browser desktop]
      },
      consumer: {
        reference: 'BILLING-TEST-001',
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
            product_name: 'Test Product',
            product_sku: 'TEST-SKU-001',
            product_type: 'physical',
            quantity: 1,
            unit_amount: 100.00
          }
        ],
        shipping: {
          first_name: 'Ship',
          last_name: 'To',
          phone: '6145675309',
          email: 'ship@example.com',
          street: '123 Ship St',
          city: 'Columbus',
          state: 'OH',
          zip: '43221',
          country: 'US'
        },
        # Try adding billing field
        billing: {
          first_name: 'Bill',
          last_name: 'To',
          phone: '6145675310',
          email: 'bill@example.com',
          street: '456 Billing Ave',
          city: 'New York',
          state: 'NY',
          zip: '10001',
          country: 'US'
        }
      }
    )

    puts "\n✅ Test 1 SUCCESS: API accepts billing address field!"
    puts "Charge ID: #{response.dig('data', 'id')}"
    puts '=' * 80
  rescue CitconPay::APIError => e
    puts "\n❌ Test 1 FAILED: API rejected billing address field"
    puts "Error: #{e.message}"
    puts "Error Code: #{e.error_code}"
    puts '=' * 80
  end
end

puts "\n\n"
puts '=' * 80
puts 'Test 2: Alipay charge with service product + billing address (no shipping)'
puts '=' * 80

# Test 2: Service product with billing address but NO shipping
VCR.use_cassette('billing_tests/alipay_service_with_billing_no_shipping', record: :new_episodes) do
  begin
    response = client.charges.create(
      transaction: {
        reference: "BILLING-TEST-SERVICE-#{Time.now.to_i}",
        amount: 150.00,
        currency: 'USD',
        country: 'US',
        country_accelerator: 'CN',
        note: 'Testing service with billing, no shipping'
      },
      payment: {
        method: 'alipay',
        client: %w[mobile_browser desktop]
      },
      consumer: {
        reference: 'BILLING-TEST-002',
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
            product_name: 'Consulting Service',
            product_sku: 'SERVICE-001',
            product_type: 'service',
            quantity: 1,
            unit_amount: 150.00
          }
        ],
        # Billing address but NO shipping address
        billing: {
          first_name: 'Bill',
          last_name: 'To',
          phone: '6145675310',
          email: 'bill@example.com',
          street: '456 Billing Ave',
          city: 'New York',
          state: 'NY',
          zip: '10001',
          country: 'US'
        }
      }
    )

    puts "\n✅ Test 2 SUCCESS: Service with billing (no shipping) works!"
    puts "Charge ID: #{response.dig('data', 'id')}"
    puts '=' * 80
  rescue CitconPay::APIError => e
    puts "\n❌ Test 2 FAILED"
    puts "Error: #{e.message}"
    puts "Error Code: #{e.error_code}"
    puts '=' * 80
  end
end

puts "\n\n"
puts '=' * 80
puts 'Test 3: Alipay service product - NO billing, NO shipping (baseline from earlier tests)'
puts '=' * 80
puts "This already passed in our earlier tests - service products don't need addresses!"
puts '=' * 80
