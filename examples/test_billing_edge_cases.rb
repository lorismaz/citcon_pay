#!/usr/bin/env ruby
# frozen_string_literal: true

# Test edge cases that might trigger billing address requirement

require 'bundler/setup'
require 'citcon_pay'

CitconPay.configure do |config|
  config.api_key = ENV.fetch('CITCON_API_KEY', 'sk-uat-d5ecc6d9bdd0c729fe8481438590221c')
  config.environment = :sandbox
  config.log_level = :debug
end

client = CitconPay::Client.new

puts '=' * 80
puts 'Testing edge cases that might trigger billing address requirement'
puts '=' * 80

# Test 5: Different product types
product_types = %w[service physical digital_product physical_product digital_service physical_service]

product_types.each_with_index do |product_type, index|
  puts "\n🧪 Test #{index + 5}: Product type '#{product_type}' with NO addresses"
  puts '-' * 80
  begin
    response = client.charges.create(
      transaction: {
        reference: "DEBUG-TYPE-#{product_type.upcase}-#{Time.now.to_i}",
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
            product_name: "Test #{product_type}",
            product_type: product_type,
            quantity: 1,
            unit_amount: 100.00
          }
        ]
      }
    )
    puts "✅ SUCCESS (#{product_type}): #{response.dig('data', 'id')}"
  rescue CitconPay::APIError => e
    puts "❌ FAILED (#{product_type}): #{e.message}"
    puts "Error Code: #{e.error_code}"
    puts "Response: #{e.response}"
  end
end

# Test: With only mobile_browser client
puts "\n🧪 Test: Mobile browser ONLY client type"
puts '-' * 80
begin
  response = client.charges.create(
    transaction: {
      reference: "DEBUG-MOBILE-ONLY-#{Time.now.to_i}",
      amount: 100.00,
      currency: 'USD',
      country: 'US',
      country_accelerator: 'CN'
    },
    payment: {
      method: 'alipay',
      client: ['mobile_browser']  # Only mobile
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
  puts "✅ SUCCESS (mobile only): #{response.dig('data', 'id')}"
rescue CitconPay::APIError => e
  puts "❌ FAILED: #{e.message}"
  puts "Error Code: #{e.error_code}"
end

# Test: With only desktop client
puts "\n🧪 Test: Desktop ONLY client type"
puts '-' * 80
begin
  response = client.charges.create(
    transaction: {
      reference: "DEBUG-DESKTOP-ONLY-#{Time.now.to_i}",
      amount: 100.00,
      currency: 'USD',
      country: 'US',
      country_accelerator: 'CN'
    },
    payment: {
      method: 'alipay',
      client: ['desktop']  # Only desktop
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
  puts "✅ SUCCESS (desktop only): #{response.dig('data', 'id')}"
rescue CitconPay::APIError => e
  puts "❌ FAILED: #{e.message}"
  puts "Error Code: #{e.error_code}"
end

# Test: With auto_capture = false
puts "\n🧪 Test: auto_capture = false"
puts '-' * 80
begin
  response = client.charges.create(
    transaction: {
      reference: "DEBUG-NO-AUTO-CAPTURE-#{Time.now.to_i}",
      amount: 100.00,
      currency: 'USD',
      country: 'US',
      country_accelerator: 'CN',
      auto_capture: false  # Manual capture
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
  puts "✅ SUCCESS (manual capture): #{response.dig('data', 'id')}"
rescue CitconPay::APIError => e
  puts "❌ FAILED: #{e.message}"
  puts "Error Code: #{e.error_code}"
end

puts "\n" + '=' * 80
puts "Edge case testing complete"
puts '=' * 80
