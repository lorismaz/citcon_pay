#!/usr/bin/env ruby
# frozen_string_literal: true

# This script tests if passing product_type: 'service' allows omitting the shipping address
# for Alipay charges.

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
  config.filter_sensitive_data('<ACCESS_TOKEN>') do |interaction|
    if interaction.response.body.is_a?(String)
      begin
        body = JSON.parse(interaction.response.body)
        body.dig('data', 'access_token')
      rescue JSON::ParserError
        nil
      end
    end
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
puts 'Testing Alipay charge with product_type: "service" (NO shipping address)'
puts '=' * 80

VCR.use_cassette('charge/alipay_service_no_shipping', record: :new_episodes) do
  begin
    response = client.charges.create(
      transaction: {
        reference: "ALIPAY-SERVICE-#{Time.now.to_i}",
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
      # Include goods with service product_type but NO shipping address
      goods: {
        data: [
          {
            product_name: 'Business Consulting Service',
            product_sku: 'SERVICE-CONSULT-001',
            product_type: 'service', # <-- Testing service type
            quantity: 1,
            unit_amount: 150.00,
            description: 'Professional business consulting - 3 hours'
          }
        ]
        # NO shipping parameter included!
      }
    )

    puts "\n✅ Charge created successfully!"
    puts '=' * 80
    puts "Charge ID: #{response.dig('data', 'id')}"
    puts "Reference: #{response.dig('data', 'reference')}"
    puts "Status: #{response.dig('data', 'status')}"
    puts "Amount: $#{response.dig('data', 'amount')}"
    puts "Payment URL: #{response.dig('data', 'payment_url')}"
    puts '=' * 80
    puts "\n✅ RESULT: Service product type ALLOWS omitting shipping address!"
    puts "✅ VCR cassette recorded: spec/fixtures/vcr_cassettes/charge/alipay_service_no_shipping.yml"
    puts "\nFull response:"
    puts JSON.pretty_generate(response)
  rescue CitconPay::APIError => e
    puts "\n❌ Charge creation failed!"
    puts '=' * 80
    puts "Error: #{e.message}"
    puts "Status Code: #{e.status_code}"
    puts "Error Code: #{e.error_code}"
    puts "Response: #{e.response}"
    puts '=' * 80
    puts "\n❌ RESULT: Service product type REQUIRES shipping address (or other validation failed)"
    puts "\nThis means we cannot bypass shipping address even with product_type: 'service'"
  end
end
