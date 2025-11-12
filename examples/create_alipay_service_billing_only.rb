#!/usr/bin/env ruby
# frozen_string_literal: true

# This script demonstrates that service products can use billing addresses
# WITHOUT shipping addresses (since services don't need physical delivery)

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
puts 'Alipay Service Charge: BILLING address only (NO shipping)'
puts '=' * 80
puts 'Demonstrates: Service products can have billing without shipping'
puts '=' * 80

VCR.use_cassette('charge/alipay_service_billing_only', record: :new_episodes) do
  begin
    response = client.charges.create(
      transaction: {
        reference: "ALIPAY-SERVICE-BILLING-#{Time.now.to_i}",
        amount: 199.00,
        currency: 'USD',
        country: 'US',
        country_accelerator: 'CN',
        note: 'Service charge with billing address only'
      },
      payment: {
        method: 'alipay',
        client: %w[mobile_browser desktop]
      },
      consumer: {
        reference: 'CUSTOMER-BILLING-001',
        first_name: 'Sarah',
        last_name: 'Johnson',
        phone: '13312345678',
        email: 'sarah.johnson@example.com'
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
            product_name: 'Annual SaaS Subscription',
            product_sku: 'SAAS-ANNUAL-PRO',
            product_type: 'service', # Service type
            quantity: 1,
            unit_amount: 199.00,
            description: 'Professional plan - 12 months access'
          }
        ],
        # Billing address for payment/invoicing purposes
        billing: {
          first_name: 'Sarah',
          last_name: 'Johnson',
          phone: '2125551234',
          email: 'billing@company.com',
          street: '1 Corporate Plaza, Suite 500',
          city: 'New York',
          state: 'NY',
          zip: '10001',
          country: 'US'
        }
        # Note: NO shipping address - services don't need physical delivery!
      }
    )

    puts "\n✅ Charge created successfully!"
    puts '=' * 80
    puts "Charge ID: #{response.dig('data', 'id')}"
    puts "Reference: #{response.dig('data', 'reference')}"
    puts "Status: #{response.dig('data', 'status')}"
    puts "Amount: $#{response.dig('data', 'amount')}"
    puts '=' * 80
    puts "\n✅ RESULT: Service products CAN use billing address WITHOUT shipping!"
    puts "✅ VCR cassette: spec/fixtures/vcr_cassettes/charge/alipay_service_billing_only.yml"
    puts "\nUse Case: Digital services that need billing info for invoicing/accounting"
    puts "Examples: SaaS subscriptions, cloud services, professional services"
  rescue CitconPay::APIError => e
    puts "\n❌ Charge creation failed!"
    puts '=' * 80
    puts "Error: #{e.message}"
    puts "Status Code: #{e.status_code}"
    puts "Error Code: #{e.error_code}"
    puts '=' * 80
  end
end
