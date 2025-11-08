# frozen_string_literal: true

require_relative "base"

module CitconPay
  module Resources
    class Refund < Base
      # Create a refund
      #
      # @param id [String] Transaction ID to refund (required)
      # @param reference [String] Merchant refund reference ID (required)
      # @param transaction_reference [String] Original transaction reference
      # @param amount [Numeric] Refund amount (required)
      # @param note [String] Refund note/reason
      #
      # @return [Hash] Response containing refund details
      #
      # @example Full refund
      #   client.refunds.create(
      #     id: "2000161754397568069637",
      #     reference: "REFUND-123",
      #     transaction_reference: "ORDER-123",
      #     amount: 100.00,
      #     note: "Customer requested refund"
      #   )
      #
      # @example Partial refund
      #   client.refunds.create(
      #     id: "2000161754397568069637",
      #     reference: "REFUND-124",
      #     amount: 50.00,
      #     note: "Partial refund"
      #   )
      def create(id:, reference:, amount:, transaction_reference: nil, note: nil)
        body = {
          id: id,
          reference: reference,
          amount: amount
        }

        body[:transaction_reference] = transaction_reference if transaction_reference
        body[:note] = note if note

        post("refunds", body: body)
      end

      # Retrieve a specific refund
      # @param id [String] Refund ID
      # @return [Hash] Refund details
      def retrieve(id)
        get("refunds/#{id}")
      end

      # List refunds for a transaction
      # @param transaction_id [String] Transaction ID
      # @return [Hash] List of refunds
      def list_by_transaction(transaction_id)
        get("transactions/#{transaction_id}/refunds")
      end
    end
  end
end
