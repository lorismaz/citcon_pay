#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require_relative '../lib/citcon_pay'

# Configure CitconPay
CitconPay.configure do |config|
  config.api_key = ENV.fetch('CITCON_API_KEY', 'sk-uat-d5ecc6d9bdd0c729fe8481438590221c')
  config.environment = :sandbox
end

# Create a client
client = CitconPay::Client.new

# Transaction details (replace with actual values)
transaction_id = ARGV[0] || '2000161754397568069637'
amount = (ARGV[1] || '50.00').to_f

puts 'Processing refund...'
puts "Transaction ID: #{transaction_id}"
puts "Refund Amount: #{amount}"

begin
  # Create a refund
  response = client.refunds.create(
    id: transaction_id,
    reference: "REFUND-#{Time.now.to_i}",
    transaction_reference: 'ORDER-12345', # Optional
    amount: amount,
    note: 'Customer requested refund'
  )

  puts "\nRefund created successfully!"
  puts "Refund ID: #{response.dig('data', 'id')}"
  puts "Status: #{response.dig('data', 'status')}"
  puts "Amount: #{response.dig('data', 'amount')}"

  puts "\nFull Response:"
  puts JSON.pretty_generate(response)
rescue CitconPay::ValidationError => e
  puts "\nValidation error: #{e.message}"
  puts 'Make sure the transaction ID is correct and the transaction can be refunded'
rescue CitconPay::APIError => e
  puts "\nError processing refund:"
  puts "Error: #{e.message}"
  puts "Status: #{e.status_code}"
end

puts "\n---\n\nUsage:"
puts "ruby #{__FILE__} TRANSACTION_ID AMOUNT"
puts "Example: ruby #{__FILE__} 2000161754397568069637 50.00"
