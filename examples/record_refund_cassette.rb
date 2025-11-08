#!/usr/bin/env ruby
# frozen_string_literal: true

# This script helps record VCR cassettes for refund tests by:
# 1. Creating a charge
# 2. Waiting for manual payment completion
# 3. Recording the refund API calls

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

def create_charge(client, reference, amount)
  puts "\n=== Creating charge ==="
  puts "Reference: #{reference}"
  puts "Amount: $#{amount}"

  charge_response = client.charges.create(
    transaction: {
      reference: reference,
      amount: amount,
      currency: 'USD',
      country: 'US',
      note: "Refund test payment - #{reference}"
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

  transaction_id = charge_response.dig('data', 'id')
  payment_urls = charge_response.dig('data', 'payment', 'client')

  puts "\nCharge created successfully!"
  puts "Transaction ID: #{transaction_id}"
  puts "Status: #{charge_response.dig('data', 'status')}"

  if payment_urls && payment_urls.any?
    redirect_url = payment_urls.find { |c| c['format'] == 'redirect' && c['client'] == 'desktop' }
    puts "\n🔗 Payment URL (desktop):"
    puts redirect_url['content'] if redirect_url
  end

  transaction_id
end

def wait_for_payment_completion(client, transaction_id)
  puts "\n⏳ Waiting for payment completion..."
  puts 'Please complete the payment using the URL above.'
  puts "Press ENTER when you've completed the payment..."
  gets

  # Check transaction status
  transaction = client.transactions.retrieve(transaction_id)
  status = transaction.dig('data', 'status')

  puts "\nCurrent transaction status: #{status}"

  if status != 'success'
    puts "⚠️  Warning: Transaction is not in 'success' status."
    puts 'Refund may fail. Continue anyway? (y/n)'
    response = gets.chomp.downcase
    return false unless response == 'y'
  end

  true
end

def record_refund(client, cassette_name, transaction_id, reference, amount, note)
  puts "\n=== Recording refund cassette: #{cassette_name} ==="

  VCR.use_cassette(cassette_name, record: :new_episodes) do
    refund_response = client.refunds.create(
      id: transaction_id,
      reference: reference,
      amount: amount,
      note: note
    )

    puts "\n✅ Refund successful!"
    puts "Refund ID: #{refund_response.dig('data', 'id')}"
    puts "Refund Reference: #{refund_response.dig('data', 'reference')}"
    puts "Amount: $#{refund_response.dig('data', 'amount')}"
    puts "\n✅ Cassette recorded: spec/fixtures/vcr_cassettes/#{cassette_name}.yml"

    refund_response
  rescue CitconPay::APIError => e
    puts "\n❌ Refund failed!"
    puts "Error: #{e.message}"
    puts "Status code: #{e.status_code}"
    puts "Error code: #{e.error_code}"
    puts "Response: #{e.response.inspect}"
    nil
  end
end

# Main script
puts '=' * 60
puts 'CitconPay Refund Cassette Recording Helper'
puts '=' * 60

client = CitconPay::Client.new

# Test 1: Full Refund
puts "\n\n📝 Test 1: Full Refund"
puts '-' * 60
transaction_id_1 = create_charge(client, 'TEST-VCR-REFUND-FULL', 100)

if wait_for_payment_completion(client, transaction_id_1)
  record_refund(
    client,
    'refund/create_full_refund_success',
    transaction_id_1,
    'REFUND-FULL-001',
    100.00,
    'Customer requested full refund'
  )
end

puts "\n\nWould you like to record partial refund tests? (y/n)"
response = gets.chomp.downcase
exit unless response == 'y'

# Test 2: Partial Refund
puts "\n\n📝 Test 2: Partial Refund"
puts '-' * 60
transaction_id_2 = create_charge(client, 'TEST-VCR-REFUND-PARTIAL', 200)

if wait_for_payment_completion(client, transaction_id_2)
  record_refund(
    client,
    'refund/create_partial_refund_success',
    transaction_id_2,
    'REFUND-PARTIAL-001',
    100.00,
    'Partial refund for one item'
  )
end

# Test 3: Multiple Partial Refunds
puts "\n\n📝 Test 3: Multiple Partial Refunds"
puts '-' * 60
transaction_id_3 = create_charge(client, 'TEST-VCR-REFUND-MULTIPLE', 300)

if wait_for_payment_completion(client, transaction_id_3)
  # First partial refund
  puts "\n--- First partial refund ($100) ---"
  record_refund(
    client,
    'refund/create_multiple_partial_refunds_first',
    transaction_id_3,
    'REFUND-PARTIAL-002',
    100.00,
    'First partial refund'
  )

  # Second partial refund
  puts "\n--- Second partial refund ($100) ---"
  record_refund(
    client,
    'refund/create_multiple_partial_refunds_second',
    transaction_id_3,
    'REFUND-PARTIAL-003',
    100.00,
    'Second partial refund'
  )
end

puts "\n\n" + '=' * 60
puts '✅ Refund cassette recording complete!'
puts '=' * 60
puts "\nNext steps:"
puts '1. Update spec/integration/refund_integration_spec.rb to use the new cassettes'
puts "2. Remove the 'skip: true' from the refund tests"
puts '3. Run: bundle exec rspec spec/integration/refund_integration_spec.rb'
