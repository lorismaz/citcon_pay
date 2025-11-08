#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require_relative '../lib/citcon_pay'

# Configure CitconPay
CitconPay.configure do |config|
  config.api_key = ENV.fetch('CITCON_API_KEY', 'sk-uat-d5ecc6d9bdd0c729fe8481438590221c')
  config.environment = :sandbox
  config.log_level = :debug
end

# Create a client
client = CitconPay::Client.new

puts 'Creating a charge for Alipay payment...'

begin
  # Create a charge
  response = client.charges.create(
    transaction: {
      reference: "EXAMPLE-#{Time.now.to_i}",
      amount: 100.00,
      currency: 'USD',
      country: 'US',
      country_accelerator: 'CN', # Important for Chinese payment methods
      note: 'Test payment from Ruby client'
    },
    payment: {
      method: 'alipay',
      client: %w[mobile_browser desktop]
    },
    consumer: {
      reference: 'CUSTOMER-123',
      first_name: 'John',
      last_name: 'Doe',
      phone: '13312345678',
      email: 'john.doe@example.com'
    },
    urls: {
      ipn: 'https://example.com/webhooks/citcon',
      success: 'https://example.com/payment/success',
      fail: 'https://example.com/payment/fail',
      cancel: 'https://example.com/payment/cancel'
    }
  )

  puts "\nCharge created successfully!"
  puts "Charge ID: #{response.dig('data', 'id')}"
  puts "Charge Token: #{response.dig('data', 'charge_token')}"
  puts "Payment URL: #{response.dig('data', 'payment_url')}"
  puts "Reference: #{response.dig('data', 'reference')}"
  puts "\nFull response:"
  puts JSON.pretty_generate(response)
rescue CitconPay::APIError => e
  puts "\nError creating charge:"
  puts "Error: #{e.message}"
  puts "Status Code: #{e.status_code}"
  puts "Error Code: #{e.error_code}"
  puts "Response: #{e.response}"
end
