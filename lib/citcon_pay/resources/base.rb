# frozen_string_literal: true

module CitconPay
  module Resources
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end

      private

      def get(path, params: {}, headers: {})
        client.get(path, params: params, headers: headers)
      end

      def post(path, body: {}, headers: {})
        client.post(path, body: body, headers: headers)
      end

      def put(path, body: {}, headers: {})
        client.put(path, body: body, headers: headers)
      end

      def delete(path, headers: {})
        client.delete(path, headers: headers)
      end
    end
  end
end
