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

# Get transaction ID from command line or use a default
transaction_id = ARGV[0] || '2000119337339913846789'

puts "Querying transaction: #{transaction_id}"

begin
  # Retrieve transaction by ID
  transaction = client.transactions.retrieve(transaction_id)

  puts "\nTransaction Details:"
  puts "ID: #{transaction.dig('data', 'id')}"
  puts "Reference: #{transaction.dig('data', 'reference')}"
  puts "Status: #{transaction.dig('data', 'status')}"
  puts "Amount: #{transaction.dig('data', 'amount')} #{transaction.dig('data', 'currency')}"
  puts "Payment Method: #{transaction.dig('data', 'payment', 'method')}"
  puts "Created At: #{transaction.dig('data', 'created_at')}"

  # Check status using helper methods
  puts "\nStatus Checks:"
  puts "Successful? #{client.transactions.successful?(transaction_id)}"
  puts "Pending? #{client.transactions.pending?(transaction_id)}"
  puts "Failed? #{client.transactions.failed?(transaction_id)}"

  puts "\nFull Response:"
  puts JSON.pretty_generate(transaction)
rescue CitconPay::NotFoundError => e
  puts "\nTransaction not found: #{e.message}"
rescue CitconPay::APIError => e
  puts "\nError: #{e.message}"
  puts "Status: #{e.status_code}"
end

puts "\n---\n\nYou can also query by reference:"
puts "ruby #{__FILE__} ORDER-12345"
