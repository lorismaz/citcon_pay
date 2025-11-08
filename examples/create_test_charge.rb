#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple script to create a test charge for refund testing

require 'bundler/setup'
require 'citcon_pay'

CitconPay.configure do |config|
  config.api_key = ENV.fetch('CITCON_API_KEY', 'sk-uat-d5ecc6d9bdd0c729fe8481438590221c')
  config.environment = :sandbox
end

client = CitconPay::Client.new

reference = ARGV[0] || "TEST-REFUND-#{Time.now.to_i}"
amount = (ARGV[1] || 100).to_i

puts 'Creating test charge...'
puts "Reference: #{reference}"
puts "Amount: $#{amount}"
puts ''

response = client.charges.create(
  transaction: {
    reference: reference,
    amount: amount,
    currency: 'USD',
    country: 'US',
    note: "Refund test - #{reference}"
  },
  payment: {
    method: 'paypal',
    client: %w[mobile_browser desktop]
  },
  urls: {
    ipn: 'https://example.com/webhooks/citcon',
    success: 'https://example.com/payment/success',
    fail: 'https://example.com/payment/fail'
  }
)

transaction_id = response.dig('data', 'id')
payment_clients = response.dig('data', 'payment', 'client')
desktop_redirect = payment_clients&.find { |c| c['format'] == 'redirect' && c['client'] == 'desktop' }

puts '✅ Charge created successfully!'
puts ''
puts "Transaction ID: #{transaction_id}"
puts "Reference: #{reference}"
puts "Amount: $#{amount}"
puts "Status: #{response.dig('data', 'status')}"
puts ''
puts '🔗 Payment URL:'
puts desktop_redirect['content'] if desktop_redirect
puts ''
puts 'Next steps:'
puts '1. Open the URL above and complete the payment'
puts '2. After payment is complete, run:'
puts "   CITCON_API_KEY=#{ENV['CITCON_API_KEY']} ruby examples/record_refund.rb #{transaction_id} #{reference}"
