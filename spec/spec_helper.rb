# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "citcon_pay"
require "webmock/rspec"
require "vcr"

# Configure VCR for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.filter_sensitive_data("<API_KEY>") { ENV["CITCON_API_KEY"] }
  config.filter_sensitive_data("<ACCESS_TOKEN>") { |interaction|
    auth_header = interaction.response.headers["Authorization"]&.first
    auth_header&.gsub(/^Bearer /, "")
  }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset configuration before each test
  config.before do
    CitconPay.reset_configuration!
  end

  # Helper to configure CitconPay for tests
  config.before do |example|
    next unless example.metadata[:configure_citcon]

    CitconPay.configure do |c|
      c.api_key = ENV.fetch("CITCON_API_KEY", "test-api-key")
      c.environment = :sandbox
      c.timeout = 10
      c.log_level = :info
    end
  end
end

# Helper methods for specs
module SpecHelpers
  def stub_access_token_request(api_key: "test-api-key", access_token: "test-access-token")
    stub_request(:post, "https://api.sandbox.citconpay.com/v1/access-tokens")
      .with(
        headers: {
          "Authorization" => "Bearer #{api_key}",
          "Content-Type" => "application/json"
        },
        body: { token_type: "server" }.to_json
      )
      .to_return(
        status: 200,
        body: {
          data: {
            access_token: access_token,
            token_type: "server"
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_charge_request(charge_data: {}, response_data: {})
    default_response = {
      data: {
        id: "test-charge-id",
        charge_token: "test-charge-token",
        reference: charge_data.dig(:transaction, :reference) || "TEST-REF",
        payment_url: "https://pay.citconpay.com/test",
        status: "pending"
      }
    }

    stub_request(:post, "https://api.sandbox.citconpay.com/v1/charges")
      .with(
        headers: {
          "Authorization" => "Bearer test-access-token",
          "Content-Type" => "application/json"
        },
        body: charge_data.to_json
      )
      .to_return(
        status: 200,
        body: default_response.merge(response_data).to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_transaction_request(transaction_id:, transaction_data: {})
    default_data = {
      data: {
        id: transaction_id,
        reference: "TEST-REF",
        status: "success",
        amount: 100.00,
        currency: "USD"
      }
    }

    stub_request(:get, "https://api.sandbox.citconpay.com/v1/transactions/#{transaction_id}")
      .with(
        headers: {
          "Authorization" => "Bearer test-access-token",
          "Content-Type" => "application/json"
        }
      )
      .to_return(
        status: 200,
        body: default_data.deep_merge(transaction_data).to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end

RSpec.configure do |config|
  config.include SpecHelpers
end
