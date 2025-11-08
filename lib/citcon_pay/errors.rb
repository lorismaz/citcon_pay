# frozen_string_literal: true

module CitconPay
  class Error < StandardError; end

  class ConfigurationError < Error; end

  class APIError < Error
    attr_reader :response, :status_code, :error_code

    def initialize(message, response: nil, status_code: nil, error_code: nil)
      super(message)
      @response = response
      @status_code = status_code
      @error_code = error_code
    end
  end

  class AuthenticationError < APIError; end

  class ValidationError < APIError; end

  class NotFoundError < APIError; end

  class RateLimitError < APIError; end

  class ServerError < APIError; end

  class NetworkError < Error; end

  class TimeoutError < NetworkError; end
end
