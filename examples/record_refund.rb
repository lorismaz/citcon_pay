#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to record a refund after payment completion

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
end

transaction_id = ARGV[0]
original_reference = ARGV[1]
refund_amount = (ARGV[2] || nil)&.to_f
refund_reference = ARGV[3] || "REFUND-#{original_reference}"
cassette_name = ARGV[4] || 'refund/create_refund_success'

unless transaction_id
  puts 'Usage: ruby examples/record_refund.rb TRANSACTION_ID ORIGINAL_REFERENCE [AMOUNT] [REFUND_REF] [CASSETTE]'
  puts ''
  puts 'Examples:'
  puts '  # Full refund'
  puts '  ruby examples/record_refund.rb 2000... TEST-REF-001 100 REFUND-001 refund/full_refund'
  puts ''
  puts '  # Partial refund'
  puts '  ruby examples/record_refund.rb 2000... TEST-REF-002 50 REFUND-002 refund/partial_refund'
  exit 1
end

# Check transaction status first (outside VCR to verify before recording)
puts 'Checking transaction status...'
client = CitconPay::Client.new
transaction = client.transactions.retrieve(transaction_id)
status = transaction.dig('data', 'status')
amount = transaction.dig('data', 'amount')

puts "Transaction ID: #{transaction_id}"
puts "Reference: #{transaction.dig('data', 'reference')}"
puts "Amount: $#{amount}"
puts "Status: #{status}"
puts ''

if status != 'success' && status != 'succeeded'
  puts "⚠️  Warning: Transaction status is '#{status}', not 'success' or 'succeeded'"
  puts 'Refund may fail. Do you want to continue? (y/n)'
  answer = STDIN.gets&.chomp&.downcase
  exit unless answer == 'y'
end

refund_amount ||= amount

puts 'Recording refund...'
puts "Cassette: #{cassette_name}"
puts "Refund amount: $#{refund_amount}"
puts ''

VCR.use_cassette(cassette_name, record: :new_episodes) do
  # Create a fresh client inside the VCR block to record authentication
  fresh_client = CitconPay::Client.new
  response = fresh_client.refunds.create(
    id: transaction_id,
    reference: refund_reference,
    amount: refund_amount,
    note: "Test refund for #{original_reference}"
  )

  puts '✅ Refund successful!'
  puts ''
  puts "Refund ID: #{response.dig('data', 'id')}"
  puts "Reference: #{response.dig('data', 'reference')}"
  puts "Amount: $#{response.dig('data', 'amount')}"
  puts "Status: #{response.dig('data', 'status')}"
  puts ''
  puts "✅ Cassette saved: spec/fixtures/vcr_cassettes/#{cassette_name}.yml"
rescue CitconPay::APIError => e
  puts '❌ Refund failed!'
  puts "Error: #{e.message}"
  puts "Status: #{e.status_code}"
  puts "Code: #{e.error_code}"
  puts "Response: #{e.response.inspect}"
  exit 1
end
