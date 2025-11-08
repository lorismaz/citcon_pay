# frozen_string_literal: true

require_relative "base"

module CitconPay
  module Resources
    class AccessToken < Base
      # Create a new access token
      # @param token_type [String] The type of token (default: 'server')
      # @return [Hash] Response containing the access token
      def create(token_type: "server")
        client.authenticate!
        {
          "data" => {
            "access_token" => client.access_token,
            "token_type" => token_type
          }
        }
      end

      # Get the current access token
      # @return [String, nil] The current access token
      def current
        client.access_token
      end

      # Check if authenticated
      # @return [Boolean] True if authenticated
      def authenticated?
        client.authenticated?
      end
    end
  end
end
