# frozen_string_literal: true

require_relative 'base'

module CitconPay
  module Resources
    class Charge < Base
      # Create a new charge
      #
      # @param transaction [Hash] Transaction details
      # @option transaction [String] :reference Merchant reference ID (required)
      # @option transaction [Numeric] :amount Transaction amount (required)
      # @option transaction [String] :currency Currency code (required, e.g., 'USD', 'CNY')
      # @option transaction [String] :country Country code (required)
      # @option transaction [String] :country_accelerator Country accelerator (e.g., 'CN' for China)
      # @option transaction [String] :note Transaction note
      #
      # @param payment [Hash] Payment details
      # @option payment [String] :method Payment method (required, e.g., 'alipay', 'wechatpay', 'upop')
      # @option payment [String] :indicator Payment indicator
      # @option payment [Boolean] :request_token Whether to request a payment token
      # @option payment [String] :token Existing payment token
      # @option payment [Array<String>] :client Client types (e.g., ['mobile_browser', 'desktop'])
      # @option payment [Integer] :expiry Token expiry timestamp
      #
      # @param consumer [Hash] Consumer details (optional)
      # @option consumer [String] :reference Consumer reference ID
      # @option consumer [String] :first_name Consumer first name
      # @option consumer [String] :last_name Consumer last name
      # @option consumer [String] :phone Consumer phone number
      # @option consumer [String] :email Consumer email
      #
      # @param goods [Hash] Goods and shipping details (optional)
      # @option goods [Array<Hash>] :data Array of product items
      # @option goods [Hash] :shipping Shipping address details
      #
      # @param urls [Hash] Callback URLs
      # @option urls [String] :ipn IPN callback URL (required for notifications)
      # @option urls [String] :success Success redirect URL
      # @option urls [String] :fail Failure redirect URL
      # @option urls [String] :cancel Cancellation redirect URL
      # @option urls [String] :mobile Mobile redirect URL
      #
      # @return [Hash] Response containing charge details
      #
      # @example Create a basic charge
      #   client.charges.create(
      #     transaction: {
      #       reference: "ORDER-123",
      #       amount: 100.00,
      #       currency: "USD",
      #       country: "US",
      #       note: "Test payment"
      #     },
      #     payment: {
      #       method: "alipay",
      #       client: ["mobile_browser", "desktop"]
      #     },
      #     urls: {
      #       ipn: "https://example.com/ipn",
      #       success: "https://example.com/success",
      #       fail: "https://example.com/fail"
      #     }
      #   )
      #
      # @example Create a charge with consumer and goods info
      #   client.charges.create(
      #     transaction: {
      #       reference: "ORDER-456",
      #       amount: 250.00,
      #       currency: "USD",
      #       country: "US",
      #       country_accelerator: "CN"
      #     },
      #     payment: {
      #       method: "wechatpay",
      #       client: ["mobile_browser"]
      #     },
      #     consumer: {
      #       reference: "USER-789",
      #       first_name: "John",
      #       last_name: "Doe",
      #       phone: "13312345678",
      #       email: "john@example.com"
      #     },
      #     goods: {
      #       data: [{
      #         name: "Test Product",
      #         quantity: 2,
      #         unit_amount: 125.00,
      #         product_type: "physical"
      #       }],
      #       shipping: {
      #         first_name: "John",
      #         last_name: "Doe",
      #         phone: "6145675309",
      #         email: "john@example.com",
      #         street: "123 Main St",
      #         city: "Columbus",
      #         state: "OH",
      #         zip: "43221",
      #         country: "US"
      #       }
      #     },
      #     urls: {
      #       ipn: "https://example.com/ipn",
      #       success: "https://example.com/success",
      #       fail: "https://example.com/fail",
      #       cancel: "https://example.com/cancel"
      #     }
      #   )
      def create(transaction:, payment:, urls:, consumer: nil, goods: nil)
        body = {
          transaction: transaction,
          payment: payment,
          urls: urls
        }

        body[:consumer] = consumer if consumer
        body[:goods] = goods if goods

        post('charges', body: body)
      end

      # List charges (if supported by API)
      # @param params [Hash] Query parameters
      # @return [Hash] List of charges
      def list(params = {})
        get('charges', params: params)
      end

      # Retrieve a specific charge
      # @param id [String] Charge ID
      # @return [Hash] Charge details
      def retrieve(id)
        get("charges/#{id}")
      end
    end
  end
end
