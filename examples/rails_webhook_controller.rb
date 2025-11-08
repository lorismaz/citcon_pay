# frozen_string_literal: true

# Example Rails controller for handling CitconPay webhooks (IPN notifications)
#
# Add this to your routes.rb:
#   post '/webhooks/citcon', to: 'webhooks/citcon#create'
#
# Make sure to add the webhook URL in your CitconPay charge creation:
#   urls: {
#     ipn: 'https://yoursite.com/webhooks/citcon',
#     ...
#   }

module Webhooks
  class CitconController < ApplicationController
    # Skip CSRF token verification for webhook endpoints
    skip_before_action :verify_authenticity_token

    def create
      # Read the raw POST body
      payload = request.body.read

      begin
        # Parse the webhook payload
        webhook_data = CitconPay::Webhook.parse_payload(payload)

        # Log the webhook for debugging
        Rails.logger.info "CitconPay Webhook Received: #{webhook_data.inspect}"

        # Extract transaction details
        transaction = CitconPay::Webhook.extract_transaction(webhook_data)
        status = CitconPay::Webhook.transaction_status(webhook_data)
        reference = transaction['reference']
        transaction_id = transaction['id']

        # Find the order
        order = Order.find_by!(reference: reference)

        # Update order based on transaction status
        case status
        when 'success'
          handle_successful_payment(order, transaction_id, webhook_data)
        when 'pending'
          handle_pending_payment(order, transaction_id, webhook_data)
        when 'failed', 'cancelled'
          handle_failed_payment(order, transaction_id, webhook_data)
        else
          Rails.logger.warn "Unknown payment status: #{status}"
        end

        # Store webhook event for audit trail
        store_webhook_event(order, webhook_data, status)

        # Verify with API as a best practice
        verify_with_api(transaction_id, status)

        # Return 200 OK to acknowledge receipt
        head :ok

      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error "Order not found for webhook: #{e.message}"
        head :not_found
      rescue JSON::ParserError => e
        Rails.logger.error "Invalid webhook JSON: #{e.message}"
        head :bad_request
      rescue => e
        Rails.logger.error "Webhook processing error: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        head :unprocessable_entity
      end
    end

    private

    def handle_successful_payment(order, transaction_id, webhook_data)
      return if order.paid? # Prevent duplicate processing

      order.transaction do
        order.update!(
          status: 'paid',
          citcon_transaction_id: transaction_id,
          paid_at: Time.current,
          webhook_status: 'success',
          last_webhook_at: Time.current
        )

        # Create payment record
        order.payments.create!(
          provider: 'citcon',
          transaction_id: transaction_id,
          amount: webhook_data.dig('data', 'transaction', 'amount'),
          currency: webhook_data.dig('data', 'transaction', 'currency'),
          status: 'completed',
          raw_response: webhook_data
        )

        # Send confirmation email
        OrderMailer.payment_confirmed(order).deliver_later

        # Fulfill order
        OrderFulfillmentJob.perform_later(order.id)
      end

      Rails.logger.info "Payment successful for order #{order.reference}"
    end

    def handle_pending_payment(order, transaction_id, webhook_data)
      order.update(
        status: 'payment_pending',
        citcon_transaction_id: transaction_id,
        webhook_status: 'pending',
        last_webhook_at: Time.current
      )

      Rails.logger.info "Payment pending for order #{order.reference}"
    end

    def handle_failed_payment(order, transaction_id, webhook_data)
      order.update(
        status: 'payment_failed',
        citcon_transaction_id: transaction_id,
        webhook_status: webhook_data.dig('data', 'status'),
        last_webhook_at: Time.current,
        failure_reason: webhook_data.dig('data', 'failure_reason')
      )

      # Notify customer
      OrderMailer.payment_failed(order).deliver_later

      Rails.logger.info "Payment failed for order #{order.reference}"
    end

    def store_webhook_event(order, webhook_data, status)
      WebhookEvent.create!(
        source: 'citcon',
        event_type: 'payment',
        order: order,
        status: status,
        payload: webhook_data,
        processed_at: Time.current
      )
    end

    # Verify payment status with CitconPay API as a best practice
    # This ensures data consistency even if webhook delivery fails
    def verify_with_api(transaction_id, webhook_status)
      return unless Rails.env.production? # Optional: only in production

      client = CitconPay::Client.new
      api_transaction = client.transactions.retrieve(transaction_id)
      api_status = api_transaction.dig('data', 'status')

      if api_status != webhook_status
        Rails.logger.warn(
          "Status mismatch: webhook=#{webhook_status}, api=#{api_status}"
        )
      end

    rescue CitconPay::APIError => e
      Rails.logger.error "Failed to verify transaction with API: #{e.message}"
      # Don't fail the webhook processing if API verification fails
    end
  end
end
