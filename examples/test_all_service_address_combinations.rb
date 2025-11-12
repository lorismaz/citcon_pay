#!/usr/bin/env ruby
# frozen_string_literal: true

# Comprehensive test of ALL possible address combinations for service product type
# Tests 4 scenarios:
#   1. NO billing, NO shipping
#   2. Billing only, NO shipping
#   3. Shipping only, NO billing
#   4. BOTH billing and shipping

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

def create_base_charge_params(reference, note)
  {
    transaction: {
      reference: reference,
      amount: 100.00,
      currency: 'USD',
      country: 'US',
      country_accelerator: 'CN',
      note: note
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
    }
  }
end

def create_service_goods(include_billing: false, include_shipping: false)
  goods = {
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
  }

  if include_billing
    goods[:billing] = {
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
  end

  if include_shipping
    goods[:shipping] = {
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
  end

  goods
end

results = []

puts '=' * 100
puts '                    COMPREHENSIVE SERVICE PRODUCT ADDRESS TESTING'
puts '=' * 100
puts "Testing all 4 combinations of billing/shipping addresses with product_type: 'service'"
puts '=' * 100
puts ''

# Test 1: NO billing, NO shipping
puts '🧪 TEST 1: Service with NO billing address, NO shipping address'
puts '-' * 100

VCR.use_cassette('service_address_tests/no_billing_no_shipping', record: :new_episodes) do
  begin
    params = create_base_charge_params(
      "SERVICE-NO-ADDR-#{Time.now.to_i}",
      'Service with no addresses'
    )
    params[:goods] = create_service_goods(include_billing: false, include_shipping: false)

    response = client.charges.create(**params)

    puts "✅ SUCCESS: Charge created without any addresses!"
    puts "   Charge ID: #{response.dig('data', 'id')}"
    puts "   Status: #{response.dig('data', 'status')}"
    puts "   VCR: service_address_tests/no_billing_no_shipping.yml"
    results << { test: 'NO billing, NO shipping', status: 'PASS', charge_id: response.dig('data', 'id') }
  rescue CitconPay::APIError => e
    puts "❌ FAILED: #{e.message} (#{e.error_code})"
    results << { test: 'NO billing, NO shipping', status: 'FAIL', error: e.message }
  end
end

puts ''
puts '=' * 100
puts ''

# Test 2: Billing only, NO shipping
puts '🧪 TEST 2: Service with billing address ONLY (NO shipping)'
puts '-' * 100

VCR.use_cassette('service_address_tests/billing_only_no_shipping', record: :new_episodes) do
  begin
    params = create_base_charge_params(
      "SERVICE-BILL-ONLY-#{Time.now.to_i}",
      'Service with billing address only'
    )
    params[:goods] = create_service_goods(include_billing: true, include_shipping: false)

    response = client.charges.create(**params)

    puts "✅ SUCCESS: Charge created with billing only (no shipping)!"
    puts "   Charge ID: #{response.dig('data', 'id')}"
    puts "   Status: #{response.dig('data', 'status')}"
    puts "   VCR: service_address_tests/billing_only_no_shipping.yml"
    results << { test: 'Billing ONLY, NO shipping', status: 'PASS', charge_id: response.dig('data', 'id') }
  rescue CitconPay::APIError => e
    puts "❌ FAILED: #{e.message} (#{e.error_code})"
    results << { test: 'Billing ONLY, NO shipping', status: 'FAIL', error: e.message }
  end
end

puts ''
puts '=' * 100
puts ''

# Test 3: Shipping only, NO billing
puts '🧪 TEST 3: Service with shipping address ONLY (NO billing)'
puts '-' * 100

VCR.use_cassette('service_address_tests/shipping_only_no_billing', record: :new_episodes) do
  begin
    params = create_base_charge_params(
      "SERVICE-SHIP-ONLY-#{Time.now.to_i}",
      'Service with shipping address only'
    )
    params[:goods] = create_service_goods(include_billing: false, include_shipping: true)

    response = client.charges.create(**params)

    puts "✅ SUCCESS: Charge created with shipping only (no billing)!"
    puts "   Charge ID: #{response.dig('data', 'id')}"
    puts "   Status: #{response.dig('data', 'status')}"
    puts "   VCR: service_address_tests/shipping_only_no_billing.yml"
    results << { test: 'Shipping ONLY, NO billing', status: 'PASS', charge_id: response.dig('data', 'id') }
  rescue CitconPay::APIError => e
    puts "❌ FAILED: #{e.message} (#{e.error_code})"
    results << { test: 'Shipping ONLY, NO billing', status: 'FAIL', error: e.message }
  end
end

puts ''
puts '=' * 100
puts ''

# Test 4: BOTH billing and shipping
puts '🧪 TEST 4: Service with BOTH billing AND shipping addresses'
puts '-' * 100

VCR.use_cassette('service_address_tests/both_billing_and_shipping', record: :new_episodes) do
  begin
    params = create_base_charge_params(
      "SERVICE-BOTH-ADDR-#{Time.now.to_i}",
      'Service with both billing and shipping'
    )
    params[:goods] = create_service_goods(include_billing: true, include_shipping: true)

    response = client.charges.create(**params)

    puts "✅ SUCCESS: Charge created with both billing and shipping!"
    puts "   Charge ID: #{response.dig('data', 'id')}"
    puts "   Status: #{response.dig('data', 'status')}"
    puts "   VCR: service_address_tests/both_billing_and_shipping.yml"
    results << { test: 'BOTH billing AND shipping', status: 'PASS', charge_id: response.dig('data', 'id') }
  rescue CitconPay::APIError => e
    puts "❌ FAILED: #{e.message} (#{e.error_code})"
    results << { test: 'BOTH billing AND shipping', status: 'FAIL', error: e.message }
  end
end

puts ''
puts '=' * 100
puts '                                    RESULTS SUMMARY'
puts '=' * 100
puts ''

results.each_with_index do |result, index|
  status_symbol = result[:status] == 'PASS' ? '✅' : '❌'
  puts "#{status_symbol} Test #{index + 1}: #{result[:test]}"
  if result[:status] == 'PASS'
    puts "   → Charge ID: #{result[:charge_id]}"
  else
    puts "   → Error: #{result[:error]}"
  end
  puts ''
end

puts '=' * 100
passed = results.count { |r| r[:status] == 'PASS' }
total = results.count
puts "Final Score: #{passed}/#{total} tests passed"
puts '=' * 100

if passed == total
  puts ''
  puts '🎉 ALL TESTS PASSED! 🎉'
  puts ''
  puts 'CONCLUSION: Service products (product_type: "service") are FULLY FLEXIBLE:'
  puts '  ✅ Can omit both billing and shipping addresses'
  puts '  ✅ Can include only billing address'
  puts '  ✅ Can include only shipping address'
  puts '  ✅ Can include both billing and shipping addresses'
  puts ''
  puts 'This flexibility makes sense for intangible services that may or may not need'
  puts 'physical delivery or billing information depending on the business use case.'
  puts '=' * 100
end
