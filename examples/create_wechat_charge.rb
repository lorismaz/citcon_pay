#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require_relative "../lib/citcon_pay"

# Configure CitconPay
CitconPay.configure do |config|
  config.api_key = ENV.fetch("CITCON_API_KEY", "sk-uat-d5ecc6d9bdd0c729fe8481438590221c")
  config.environment = :sandbox
  config.log_level = :debug
end

# Create a client
client = CitconPay::Client.new

puts "Creating a WeChat Pay charge..."

begin
  response = client.charges.create(
    transaction: {
      reference: "WECHAT-#{Time.now.to_i}",
      amount: 150.00,
      currency: "USD",
      country: "US",
      country_accelerator: "CN", # Important for WeChat Pay
      note: "WeChat Pay test transaction"
    },
    payment: {
      method: "wechatpay",
      client: ["mobile_browser"]
    },
    urls: {
      ipn: "https://example.com/webhooks/citcon",
      success: "https://example.com/payment/success",
      fail: "https://example.com/payment/fail",
      cancel: "https://example.com/payment/cancel"
    }
  )

  puts "\nWeChat Pay charge created successfully!"
  puts "Charge ID: #{response.dig('data', 'id')}"
  puts "Payment URL: #{response.dig('data', 'payment_url')}"
  puts "\nScan the QR code at the payment URL to complete the payment"

rescue CitconPay::APIError => e
  puts "\nError: #{e.message}"
  puts "Status: #{e.status_code}"
end
