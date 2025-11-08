# frozen_string_literal: true

require 'openssl'
require 'json'

module CitconPay
  module Webhook
    class << self
      # Verify webhook signature (if CitconPay provides signature verification)
      #
      # @param payload [String] Raw webhook payload
      # @param signature [String] Webhook signature header
      # @param secret [String] Webhook secret
      #
      # @return [Boolean] True if signature is valid
      def verify_signature(payload, signature, secret)
        expected_signature = OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new('sha256'),
          secret,
          payload
        )

        secure_compare(signature, expected_signature)
      end

      # Parse webhook payload
      #
      # @param payload [String] Raw webhook payload (JSON string)
      #
      # @return [Hash] Parsed webhook data
      def parse_payload(payload)
        JSON.parse(payload)
      rescue JSON::ParserError => e
        raise Error, "Invalid webhook payload: #{e.message}"
      end

      # Extract transaction data from webhook
      #
      # @param payload [Hash] Parsed webhook payload
      #
      # @return [Hash] Transaction data
      def extract_transaction(payload)
        payload.dig('data', 'transaction') || payload['transaction'] || {}
      end

      # Get transaction status from webhook
      #
      # @param payload [Hash] Parsed webhook payload
      #
      # @return [String] Transaction status
      def transaction_status(payload)
        transaction = extract_transaction(payload)
        transaction['status']
      end

      # Check if webhook indicates successful payment
      #
      # @param payload [Hash] Parsed webhook payload
      #
      # @return [Boolean] True if payment was successful
      def successful_payment?(payload)
        transaction_status(payload) == 'success'
      end

      private

      # Constant-time string comparison to prevent timing attacks
      def secure_compare(a, b)
        return false if a.nil? || b.nil? || a.bytesize != b.bytesize

        l = a.unpack('C*')
        r = 0
        i = -1

        b.each_byte { |byte| r |= byte ^ l[i += 1] }
        r.zero?
      end
    end
  end
end
