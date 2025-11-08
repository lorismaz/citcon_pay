# frozen_string_literal: true

require_relative 'base'

module CitconPay
  module Resources
    class Transaction < Base
      # Retrieve a transaction by ID
      #
      # @param id [String] Transaction ID (required)
      #
      # @return [Hash] Transaction details including status, amount, payment info, etc.
      #
      # @example Get transaction by ID
      #   client.transactions.retrieve("2000119337339913846789")
      def retrieve(id)
        get("transactions/#{id}")
      end

      # Retrieve a transaction by merchant reference
      #
      # @param reference [String] Merchant reference ID (required)
      #
      # @return [Hash] Transaction details
      #
      # @example Get transaction by reference
      #   client.transactions.find_by_reference("ORDER-123")
      def find_by_reference(reference)
        get("transactions/#{reference}")
      end

      # List transactions (if supported by API)
      # @param params [Hash] Query parameters (e.g., start_date, end_date, status)
      # @return [Hash] List of transactions
      def list(params = {})
        get('transactions', params: params)
      end

      # Check transaction status
      # @param id [String] Transaction ID
      # @return [String] Transaction status
      def status(id)
        transaction = retrieve(id)
        transaction.dig('data', 'status')
      end

      # Check if transaction is successful
      # @param id [String] Transaction ID
      # @return [Boolean] True if transaction is successful
      def successful?(id)
        status(id) == 'success'
      end

      # Check if transaction is pending
      # @param id [String] Transaction ID
      # @return [Boolean] True if transaction is pending
      def pending?(id)
        status(id) == 'pending'
      end

      # Check if transaction failed
      # @param id [String] Transaction ID
      # @return [Boolean] True if transaction failed
      def failed?(id)
        %w[failed cancelled].include?(status(id))
      end
    end
  end
end
