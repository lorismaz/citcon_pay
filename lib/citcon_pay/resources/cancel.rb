# frozen_string_literal: true

require_relative "base"

module CitconPay
  module Resources
    class Cancel < Base
      # Cancel a transaction
      #
      # @param id [String] Transaction ID to cancel (required)
      # @param reference [String] Merchant cancel reference ID (required)
      # @param transaction_reference [String] Original transaction reference
      #
      # @return [Hash] Response containing cancellation details
      #
      # @example Cancel a transaction
      #   client.cancels.create(
      #     id: "eac2f1305d9411ecb2855566d9030c73",
      #     reference: "CANCEL-123",
      #     transaction_reference: "ORDER-123"
      #   )
      def create(id:, reference:, transaction_reference: nil)
        body = {
          id: id,
          reference: reference
        }

        body[:transaction_reference] = transaction_reference if transaction_reference

        post("cancels", body: body)
      end

      # Retrieve a specific cancellation
      # @param id [String] Cancel ID
      # @return [Hash] Cancellation details
      def retrieve(id)
        get("cancels/#{id}")
      end
    end
  end
end
