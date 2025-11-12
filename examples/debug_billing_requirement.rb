#!/usr/bin/env ruby
# frozen_string_literal: true

# Debug script to find what triggers "Billing address is required" error

require 'bundler/setup'
require 'citcon_pay'

CitconPay.configure do |config|
  config.api_key = ENV.fetch('CITCON_API_KEY', 'sk-uat-d5ecc6d9bdd0c729fe8481438590221c')
  config.environment = :sandbox
  config.log_level = :debug
end

client = CitconPay::Client.new

puts '=' * 80
puts 'Testing different Alipay scenarios to find billing requirement trigger'
puts '=' * 80

# Test 1: Minimal service charge (what we tested before)
puts "\n🧪 Test 1: Minimal service charge (NO goods at all)"
puts '-' * 80
begin
  response = client.charges.create(
    transaction: {
      reference: "DEBUG-NO-GOODS-#{Time.now.to_i}",
      amount: 100.00,
      currency: 'USD',
      country: 'US',
      country_accelerator: 'CN',
      note: 'No goods parameter'
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
  puts "✅ SUCCESS (no goods): #{response.dig('data', 'id')}"
rescue CitconPay::APIError => e
  puts "❌ FAILED: #{e.message}"
  puts "Error Code: #{e.error_code}"
  puts "Response: #{e.response}"
end

# Test 2: Service with goods but no addresses
puts "\n🧪 Test 2: Service product with NO addresses"
puts '-' * 80
begin
  response = client.charges.create(
    transaction: {
      reference: "DEBUG-SERVICE-NO-ADDR-#{Time.now.to_i}",
      amount: 100.00,
      currency: 'USD',
      country: 'US',
      country_accelerator: 'CN'
    },
    payment: {
      method: 'alipay',
      client: %w[mobile_browser desktop]
    },
    urls: {
      ipn: 'https://example.com/webhooks/citcon',
      success: 'https://example.com/payment/success',
      fail: 'https://example.com/payment/fail'
    },
    goods: {
      data: [
        {
          product_name: 'Test Service',
          product_type: 'service',
          quantity: 1,
          unit_amount: 100.00
        }
      ]
    }
  )
  puts "✅ SUCCESS (service, no addresses): #{response.dig('data', 'id')}"
rescue CitconPay::APIError => e
  puts "❌ FAILED: #{e.message}"
  puts "Error Code: #{e.error_code}"
  puts "Response: #{e.response}"
end

# Test 3: Physical product with no addresses (might trigger requirement)
puts "\n🧪 Test 3: PHYSICAL product with NO addresses"
puts '-' * 80
begin
  response = client.charges.create(
    transaction: {
      reference: "DEBUG-PHYSICAL-NO-ADDR-#{Time.now.to_i}",
      amount: 100.00,
      currency: 'USD',
      country: 'US',
      country_accelerator: 'CN'
    },
    payment: {
      method: 'alipay',
      client: %w[mobile_browser desktop]
    },
    urls: {
      ipn: 'https://example.com/webhooks/citcon',
      success: 'https://example.com/payment/success',
      fail: 'https://example.com/payment/fail'
    },
    goods: {
      data: [
        {
          product_name: 'Test Physical Product',
          product_type: 'physical',  # Physical product
          quantity: 1,
          unit_amount: 100.00
        }
      ]
    }
  )
  puts "✅ SUCCESS (physical, no addresses): #{response.dig('data', 'id')}"
rescue CitconPay::APIError => e
  puts "❌ FAILED: #{e.message}"
  puts "Error Code: #{e.error_code}"
  puts "Response: #{e.response}"
end

# Test 4: With consumer info
puts "\n🧪 Test 4: Service with consumer info but NO addresses"
puts '-' * 80
begin
  response = client.charges.create(
    transaction: {
      reference: "DEBUG-WITH-CONSUMER-#{Time.now.to_i}",
      amount: 100.00,
      currency: 'USD',
      country: 'US',
      country_accelerator: 'CN'
    },
    payment: {
      method: 'alipay',
      client: %w[mobile_browser desktop]
    },
    consumer: {
      reference: 'CUSTOMER-001',
      first_name: 'Test',
      last_name: 'User',
      email: 'test@example.com'
    },
    urls: {
      ipn: 'https://example.com/webhooks/citcon',
      success: 'https://example.com/payment/success',
      fail: 'https://example.com/payment/fail'
    },
    goods: {
      data: [
        {
          product_name: 'Test Service',
          product_type: 'service',
          quantity: 1,
          unit_amount: 100.00
        }
      ]
    }
  )
  puts "✅ SUCCESS (with consumer): #{response.dig('data', 'id')}"
rescue CitconPay::APIError => e
  puts "❌ FAILED: #{e.message}"
  puts "Error Code: #{e.error_code}"
  puts "Response: #{e.response}"
end

puts "\n" + '=' * 80
puts "Please share YOUR exact charge creation code so I can test it!"
puts '=' * 80
